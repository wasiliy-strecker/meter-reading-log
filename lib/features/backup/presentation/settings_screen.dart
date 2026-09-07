import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/app_snack_bar.dart';
import '../application/encrypted_backup_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _working = false;
  String _workingMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Datensicherung',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Verschlüsseltes Backup erstellen'),
                  subtitle: const Text(
                    'Zähler, Fotos, PDFs und Korrekturverläufe',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_working,
                  onTap: _createBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_backup_restore_outlined),
                  title: const Text('Backup wiederherstellen'),
                  subtitle: const Text(
                    'Vorhandene neuere Einträge bleiben erhalten',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_working,
                  onTap: _restoreBackup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Datenschutz und Lizenz',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ZählerstandLog 0.1.0',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fotos auswerten, Zählerstände speichern und PDFs erstellen – alles passiert lokal auf deinem Gerät. Die App überträgt deine Zählerdaten nicht an einen Server.',
                  ),
                  SizedBox(height: 10),
                  Text('Quellcode-Lizenz: Mozilla Public License 2.0'),
                ],
              ),
            ),
          ),
          if (_working) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(_workingMessage),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    final password = await _askPassword(confirm: true);
    if (password == null) return;
    setState(() {
      _working = true;
      _workingMessage = 'Backup wird verschlüsselt …';
    });
    try {
      final backup = await ref
          .read(encryptedBackupServiceProvider)
          .create(password);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          title: 'ZählerstandLog Backup',
          text:
              '${backup.preview.meterCount} Zähler, ${backup.preview.readingCount} Ablesungen',
          files: [
            XFile(
              backup.path,
              mimeType: 'application/octet-stream',
              name: backup.path.split('/').last,
            ),
          ],
        ),
      );
    } on BackupException catch (error) {
      _showBackupError(error);
    } catch (error) {
      _showMessage('Backup konnte nicht erstellt werden: $error');
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _workingMessage = '';
        });
      }
    }
  }

  Future<void> _restoreBackup() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [EncryptedBackupService.extension],
      allowMultiple: false,
    );
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;
    final password = await _askPassword(confirm: false);
    if (password == null) return;
    setState(() {
      _working = true;
      _workingMessage = 'Backup wird geprüft …';
    });
    try {
      final service = ref.read(encryptedBackupServiceProvider);
      final preview = await service.inspect(path, password);
      if (!mounted) return;
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Backup wiederherstellen?'),
              content: Text(
                '${preview.meterCount} Zähler, ${preview.readingCount} Ablesungen und ${preview.exportCount} PDF-Nachweise werden importiert. Neuere lokale Einträge werden nicht überschrieben.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Wiederherstellen'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
      setState(() => _workingMessage = 'Backup wird wiederhergestellt …');
      final result = await service.restore(path, password);
      ref.invalidate(metersProvider);
      ref.invalidate(meterDashboardItemsProvider);
      if (mounted) {
        _showMessage(
          '${result.meters} Zähler und ${result.readings} Ablesungen wiederhergestellt; ${result.skipped} neuere Einträge übersprungen.',
        );
      }
    } on BackupException catch (error) {
      _showBackupError(error);
    } catch (error) {
      _showMessage('Backup konnte nicht wiederhergestellt werden: $error');
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _workingMessage = '';
        });
      }
    }
  }

  Future<String?> _askPassword({required bool confirm}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _BackupPasswordDialog(confirm: confirm),
    );
  }

  void _showBackupError(BackupException error) {
    final message = switch (error.failure) {
      BackupFailure.passwordTooShort =>
        'Das Passwort muss mindestens 6 Zeichen lang sein.',
      BackupFailure.invalidPassword =>
        'Das Passwort ist falsch oder das Backup wurde verändert.',
      BackupFailure.missingFile =>
        'Eine zu sichernde Datei fehlt: ${error.detail}',
      BackupFailure.integrityMismatch =>
        'Eine Datei im Backup ist beschädigt oder unvollständig.',
      BackupFailure.unsupportedVersion =>
        'Diese Backup-Version wird nicht unterstützt.',
      BackupFailure.invalidFormat =>
        'Die ausgewählte Datei ist kein gültiges ZählerstandLog-Backup.',
    };
    _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(AppSnackBar(message: message));
  }
}

class _BackupPasswordDialog extends StatefulWidget {
  const _BackupPasswordDialog({required this.confirm});

  final bool confirm;

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final TextEditingController _first = TextEditingController();
  final TextEditingController _second = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.confirm ? 'Backup-Passwort festlegen' : 'Backup-Passwort',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _first,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Passwort',
              helperText: 'Mindestens 6 Zeichen',
            ),
          ),
          if (widget.confirm) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _second,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Passwort wiederholen',
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            if (_first.text.length < 6) return;
            if (widget.confirm && _first.text != _second.text) return;
            Navigator.pop(context, _first.text);
          },
          child: const Text('Weiter'),
        ),
      ],
    );
  }
}
