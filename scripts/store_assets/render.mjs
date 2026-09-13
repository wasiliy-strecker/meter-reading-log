// Code-native layouts around unchanged, real Android screenshots. Node >= 22.
import {spawn, execFileSync} from 'node:child_process';
import {mkdtempSync, readFileSync, writeFileSync, mkdirSync, existsSync, renameSync} from 'node:fs';
import {resolve, join} from 'node:path';
import {pathToFileURL} from 'node:url';
import {setTimeout as delay} from 'node:timers/promises';

const [mode, destination] = process.argv.slice(2);
if (!['fixtures', 'assets', 'contact'].includes(mode) || !destination) {
  throw Error('Usage: node scripts/store_assets/render.mjs fixtures|assets|contact OUTPUT');
}
const out = resolve(destination);
mkdirSync(out, {recursive: true});
const profile = mkdtempSync('/dev/shm/zsl-assets-chrome-');
const chrome = spawn('google-chrome', ['--headless=new', '--no-sandbox',
  '--disable-gpu', '--disable-dev-shm-usage', '--no-first-run',
  '--no-default-browser-check', '--hide-scrollbars', '--remote-debugging-port=0',
  `--user-data-dir=${profile}`, 'about:blank'], {stdio: 'ignore'});
let socket;
try {
  for (let i = 0; !existsSync(join(profile, 'DevToolsActivePort')); i++) {
    if (i > 100) throw Error('Chrome did not start');
    await delay(100);
  }
  const port = readFileSync(join(profile, 'DevToolsActivePort'), 'utf8').split('\n')[0];
  const pages = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
  socket = new WebSocket(pages.find(p => p.type === 'page').webSocketDebuggerUrl);
  await new Promise((ok, fail) => {socket.onopen = ok; socket.onerror = fail;});
  let id = 0;
  const pending = new Map();
  socket.onmessage = ({data}) => {
    const message = JSON.parse(data);
    if (pending.has(message.id)) {
      const {ok, fail} = pending.get(message.id);
      pending.delete(message.id);
      if (message.error) fail(Error(JSON.stringify(message.error))); else ok(message.result);
    }
  };
  const call = (method, params = {}) => new Promise((ok, fail) => {
    pending.set(++id, {ok, fail});
    socket.send(JSON.stringify({id, method, params}));
  });
  const uri = p => pathToFileURL(resolve(p)).href;
  const font = `@font-face{font-family:Roboto;src:url('${uri('assets/fonts/Roboto-Regular.ttf')}')}@font-face{font-family:Roboto;src:url('${uri('assets/fonts/Roboto-Bold.ttf')}');font-weight:700}`;
  async function render(name, width, height, body, css = '') {
    const path = join(out, name);
    mkdirSync(resolve(path, '..'), {recursive: true});
    const html = join(out, 'raw/layouts', `${name}.html`);
    mkdirSync(resolve(html, '..'), {recursive:true});
    if (existsSync(`${path}.html`)) renameSync(`${path}.html`, html);
    writeFileSync(html, `<!doctype html><meta charset="utf-8"><style>${font}*{box-sizing:border-box}html,body{margin:0;width:${width}px;height:${height}px;overflow:hidden;background:#fff;font-family:Roboto,sans-serif}${css}</style>${body}`);
    await call('Emulation.setDeviceMetricsOverride', {width, height, deviceScaleFactor:1, mobile:false});
    await call('Page.navigate', {url:uri(html)});
    await delay(100);
    const ready = await call('Runtime.evaluate', {expression:'Promise.all([document.fonts.ready,...Array.from(document.images).map(i=>i.decode())])', awaitPromise:true});
    if (ready.exceptionDetails) throw Error(`Image/font loading failed for ${name}`);
    const result = await call('Page.captureScreenshot', {format:'png', captureBeyondViewport:false});
    writeFileSync(path, Buffer.from(result.data, 'base64'));
    // Lossless RGB encoding only: no changes to the screenshot content.
    execFileSync('convert', [path, `PNG24:${path}`]);
    console.log(path);
  }
  if (mode === 'fixtures') {
    const rows = [];
    const specs = [
      ['strom', 'Strom Wohnung', 'electricity', 'kWh', 12, 8505, 902],
      ['gas', 'Gas Heizung', 'gas', 'm³', 6, 432132, 8220],
      ['wasser', 'Wasser Bad', 'water', 'm³', 6, 2514, 70],
    ];
    for (const [meterId,label,type,unit,count,start,step] of specs) {
      for (let i = 0; i < count; i++) {
        const scale = meterId === 'gas' ? 2 : 1;
        const value = ((start + step*i)/10**scale).toFixed(scale);
        const digits = value.replace('.', ',').padStart(meterId==='gas'?9:8,'0');
        const file = `${meterId}-${String(i+1).padStart(2,'0')}.png`;
        const date = new Date(Date.UTC(2026, 9-count+i, 1, 8)).toISOString();
        const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="960" height="640" viewBox="0 0 960 640"><rect width="960" height="640" fill="#e7ece9"/><rect x="130" y="60" width="700" height="520" rx="38" fill="#fcfdfb" stroke="#c7d1cb" stroke-width="4"/><rect x="168" y="98" width="624" height="58" rx="10" fill="#075e54"/><text x="200" y="137" fill="white" font-family="Arial" font-size="27">${label}</text><text x="480" y="206" text-anchor="middle" fill="#63736c" font-family="Arial" font-size="20">SYNTHETISCHES DEMOBILD</text><rect x="195" y="244" width="570" height="132" rx="12" fill="#d4dfce" stroke="#b1c2af" stroke-width="5"/><text x="480" y="334" text-anchor="middle" fill="#1e3027" font-family="monospace" font-size="75" font-weight="bold">${digits}</text><text x="745" y="421" text-anchor="end" fill="#354f43" font-family="Arial" font-size="30">${unit}</text><path d="M210 477 H750" stroke="#d8e3dc" stroke-width="3"/><text x="480" y="531" text-anchor="middle" fill="#63736c" font-family="Arial" font-size="20">ZählerstandLog · Beispieldaten</text></svg>`;
        await render(file,960,640,svg);
        rows.push({meterId,label,type,unit,value,date,photo:file});
      }
    }
    writeFileSync(join(out,'readings.json'),JSON.stringify(rows,null,2));
  } else if (mode === 'contact') {
    const groups = [
      ['Smartphone', Array.from({length:6},(_,i)=>`phone/0${i+1}.png`)],
      ['7-Zoll-Tablet', ['01-dashboard','02-history','03-reading','04-backup'].map(n=>`tablet7/${n}.png`)],
      ['10-Zoll-Tablet', ['01-dashboard','02-history','03-reading','04-backup'].map(n=>`tablet10/${n}.png`)],
    ];
    let body = `<h1>ZählerstandLog <span>Store-Bilder · Build 7</span></h1><section class="branding"><img src="${uri(join(out,'icon/app-icon.png'))}"><img src="${uri(join(out,'feature/feature-graphic.png'))}"></section>`;
    for (const [title,files] of groups) {
      body += `<h2>${title}</h2><section class="${title==='Smartphone'?'phones':'tablets'}">${files.map(f=>`<figure><img src="${uri(join(out,f))}"><figcaption>${f}</figcaption></figure>`).join('')}</section>`;
    }
    await render('VORSCHAU.png',1800,2250,body,`body{background:#edf4ef;padding:45px;color:#075e54}h1{font-size:36px;margin:0 0 30px}h1 span{font-size:22px;font-weight:400;margin-left:20px}h2{font-size:24px;margin:28px 0 16px}.branding{display:flex;gap:40px;height:250px}.branding img{height:100%;width:auto}.phones,.tablets{display:grid;gap:18px}.phones{grid-template-columns:repeat(6,1fr)}.tablets{grid-template-columns:repeat(2,1fr)}figure{margin:0}figure img{width:100%;display:block}figcaption{font-size:13px;margin-top:8px}.tablets img{height:245px;object-fit:contain;background:white}.tablets{row-gap:18px}`);
  } else {
    const logo = uri('assets/branding/meter_reading_log_icon.svg');
    await render('icon/app-icon.png',512,512,`<img src="${logo}" width="512" height="512">`);
    await render('feature/feature-graphic.png',1024,500,`<div class="orb"></div><img class="logo" src="${logo}"><main><div class="eyebrow">DEIN ZÄHLERSTAND. GUT DOKUMENTIERT.</div><h1>ZählerstandLog</h1><p>Ablesen. Dokumentieren.<br>Teilen.</p><div class="foot">Offline · Mit Fotobeleg · Als PDF</div></main>`,
      `body{background:#075e54;color:white}.orb{position:absolute;width:570px;height:570px;left:630px;top:-150px;border:1px solid #40877e;border-radius:50%}.logo{position:absolute;right:64px;top:133px;width:220px;height:220px}main{position:absolute;left:64px;top:75px}.eyebrow{font-size:14px;letter-spacing:2px;color:#c9e9df}h1{font-size:55px;letter-spacing:-1.6px;margin:27px 0 16px}p{font-size:30px;line-height:1.32;margin:0;color:#f0fff8}.foot{margin-top:36px;font-size:18px;color:#c9e9df}`);
    const headlines = ['Alle Zähler\nim Blick','Zählerstand per\nFoto erfassen','Dein Verlauf,\nschnell gefunden','Mit Foto nachvollziehbar\ndokumentiert','PDF-Nachweise\neinfach teilen','Daten verschlüsselt\nsichern'];
    for (let i=0;i<headlines.length;i++) {
      const number = String(i+1).padStart(2,'0');
      const raw = join(out,`raw/phone/${number}.png`);
      if (!existsSync(raw)) throw Error(`Missing real capture: ${raw}`);
      await render(`phone/${number}.png`,1080,1920,`<header><div class="brand">ZÄHLERSTANDLOG <span>· ${number}</span></div><h1>${headlines[i].replace('\n','<br>')}</h1></header><img class="screen" src="${uri(raw)}">`,
        `body{background:#edf4ef;color:#075e54}header{height:330px;padding:45px 70px 0}.brand{font-size:22px;font-weight:700;letter-spacing:2.8px}.brand span{color:#6d897e}h1{font-size:${i===3?57:64}px;line-height:1.1;letter-spacing:-1.8px;margin:25px 0 0}.screen{display:block;height:1550px;width:auto;margin:0 auto;box-shadow:0 8px 26px #12382a20}`);
    }
  }
} finally {
  socket?.close();
  chrome.kill();
}
