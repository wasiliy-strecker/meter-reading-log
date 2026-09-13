#!/usr/bin/env bash
# Extract an existing release; never builds Flutter or touches a physical device.
set -euo pipefail
if [[ $# -ne 2 ]]; then
  echo 'Usage: bash scripts/store_assets/prepare_emulator.sh EXISTING.aab BUNDLETOOL.jar' >&2
  exit 2
fi
aab=$(realpath "$1")
bundletool=$(realpath "$2")
sdk=${ZSL_ANDROID_SDK:-/home/unknown/.local/android-sdk}
adb=${ZSL_ADB:-/home/unknown/Android/Sdk/platform-tools/adb}
port=${ZSL_EMULATOR_PORT:-5580}
if ! [[ "$port" =~ ^[0-9]+$ ]] || (( port < 5554 || port > 5682 || port % 2 )); then
  echo 'Use a free, even emulator port between 5554 and 5682.' >&2
  exit 2
fi
serial="emulator-$port"
if "$adb" devices | awk '{print $1}' | rg -qx "$serial"; then
  echo "$serial is already in use; refusing to reuse its data." >&2
  exit 1
fi
work=$(mktemp -d /dev/shm/zsl-store-assets-XXXXXX)
name="zsl_store_assets_$(date +%s)"
mkdir -p "$work/avd"
export ANDROID_AVD_HOME="$work/avd"
export ANDROID_SDK_ROOT="$sdk"
printf 'no\n' | "$sdk/cmdline-tools/latest/bin/avdmanager" create avd \
  --name "$name" --package 'system-images;android-35;google_apis;x86_64' \
  --path "$work/avd/$name.avd" --device pixel_6
java -jar "$bundletool" build-apks --bundle="$aab" --output="$work/store.apks" --mode=universal
unzip -j "$work/store.apks" universal.apk -d "$work"
nohup "$sdk/emulator/emulator" -avd "$name" -port "$port" -no-window \
  -no-audio -no-snapshot -no-boot-anim -gpu swiftshader_indirect \
  -memory 2048 -cores 4 -camera-back none -camera-front none \
  >"$work/emulator.log" 2>&1 </dev/null &
for attempt in $(seq 1 120); do
  if [[ $("$adb" -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r') == 1 ]]; then
    break
  fi
  sleep 1
done
[[ $("$adb" -s "$serial" shell getprop ro.kernel.qemu | tr -d '\r') == 1 ]]
[[ $("$adb" -s "$serial" emu avd name | head -n1 | tr -d '\r') == "$name" ]]
installed=$("$adb" -s "$serial" shell pm list packages -i com.appfactory.meter_reading_log)
if [[ -n "$installed" ]]; then
  echo 'Unexpected existing app; refusing installation.' >&2
  exit 1
fi
"$adb" -s "$serial" install -r --no-streaming "$work/universal.apk"
"$adb" -s "$serial" shell dumpsys package com.appfactory.meter_reading_log |
  rg 'versionCode=|versionName=|flags=|installerPackageName='
echo "Isolated workspace: $work"
echo "Emulator serial: $serial"
echo "Stop only this emulator when finished: $adb -s $serial emu kill"
