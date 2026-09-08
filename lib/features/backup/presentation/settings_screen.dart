import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../app/widgets/app_snack_bar.dart';
import '../../../core/utils/formatters.dart';
import '../application/backup_file_exporter.dart';
import '../application/encrypted_backup_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _working = false;
  String _workingMessage = '';
  BackupProgress? _backupProgress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_working,
      child: Scaffold(
        appBar: AppBar(title: const Text('Einstellungen')),
        body: Stack(
          children: [
            AbsorbPointer(
              absorbing: _working,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Text(
                    'Datensicherung',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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
                          leading: const Icon(
                            Icons.settings_backup_restore_outlined,
                          ),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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
                ],
              ),
            ),
            if (_working)
              Positioned.fill(
                child: _BackupWorkOverlay(
                  progress: _backupProgress,
                  fallbackMessage: _workingMessage,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    final password = await _askPassword(confirm: true);
    if (password == null) return;
    setState(() {
      _working = true;
      _workingMessage = 'Dateien werden vorbereitet …';
      _backupProgress = const BackupProgress.preparing();
    });
    try {
      final backup = await ref
          .read(encryptedBackupServiceProvider)
          .create(
            password,
            onProgress: (progress) {
              if (mounted) setState(() => _backupProgress = progress);
            },
          );
      if (!mounted) return;
      final exporter = ref.read(backupFileExporterProvider);
      if (exporter.supportsDirectSave) {
        await _saveBackup(backup, exporter);
      } else {
        _clearWorkingState();
        await exporter.share(backup);
      }
    } on BackupException catch (error) {
      _showBackupError(error);
    } catch (error) {
      _showMessage('Backup konnte nicht erstellt werden: $error');
    } finally {
      if (mounted) {
        _clearWorkingState();
      }
    }
  }

  Future<void> _saveBackup(
    CreatedBackup backup,
    BackupFileExporter exporter,
  ) async {
    while (mounted) {
      setState(() {
        _working = true;
        _workingMessage = 'Backup wird gespeichert …';
        _backupProgress = null;
      });
      BackupSaveResult? result;
      Object? saveError;
      try {
        result = await exporter.save(backup);
      } catch (error) {
        saveError = error;
      }
      if (!mounted) return;
      _clearWorkingState();

      if (result?.status == BackupSaveStatus.saved) {
        final share = await _showBackupSavedDialog(
          backup,
          result!.fileName ?? _backupFileName(backup.path),
        );
        if (share && mounted) {
          try {
            await exporter.share(backup);
          } catch (error) {
            _showMessage('Backup konnte nicht geteilt werden: $error');
          }
        }
        return;
      }

      final action = await _showBackupNotSavedDialog(
        saveFailed: saveError != null,
      );
      if (!mounted) return;
      if (action == _UnsavedBackupAction.retry) continue;
      try {
        await exporter.discard(backup);
      } catch (_) {
        // The system cache or the next backup will remove a stale temp file.
      }
      return;
    }
  }

  Future<bool> _showBackupSavedDialog(
    CreatedBackup backup,
    String fileName,
  ) async {
    final sizeInMb = backup.sizeBytes / (1024 * 1024);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle_rounded),
            title: const Text('Backup gespeichert'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('$fileName wurde im gewählten Speicherort abgelegt.'),
                const SizedBox(height: 12),
                Text(
                  '${backup.preview.meterCount} Zähler · '
                  '${backup.preview.readingCount} Ablesungen · '
                  '${backup.preview.exportCount} PDF-Nachweise\n'
                  '${sizeInMb.toStringAsFixed(1)} MB · '
                  'Erstellt am ${formatDateTime(backup.preview.createdAt)} Uhr',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Fertig', textAlign: TextAlign.center),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: const Text('Teilen', textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  Future<_UnsavedBackupAction> _showBackupNotSavedDialog({
    required bool saveFailed,
  }) async {
    return await showDialog<_UnsavedBackupAction>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PopScope(
            canPop: false,
            child: AlertDialog(
              icon: Icon(
                saveFailed
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
              ),
              title: Text(
                saveFailed
                    ? 'Backup konnte nicht gespeichert werden'
                    : 'Backup noch nicht gespeichert',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Die verschlüsselte Datei liegt nur vorübergehend in der App. Wähle einen Speicherort, damit das Backup erhalten bleibt.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () =>
                        Navigator.pop(context, _UnsavedBackupAction.discard),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(
                      'Backup verwerfen',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, _UnsavedBackupAction.retry),
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text(
                      'Speicherort wählen',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        _UnsavedBackupAction.discard;
  }

  void _clearWorkingState() {
    if (!mounted) return;
    setState(() {
      _working = false;
      _workingMessage = '';
      _backupProgress = null;
    });
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
      _backupProgress = null;
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
          _backupProgress = null;
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

enum _UnsavedBackupAction { retry, discard }

String _backupFileName(String path) => path.split(RegExp(r'[/\\]')).last;

class _BackupWorkOverlay extends StatelessWidget {
  const _BackupWorkOverlay({
    required this.progress,
    required this.fallbackMessage,
  });

  final BackupProgress? progress;
  final String fallbackMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final value = progress?.fraction;
    final title = progress == null
        ? fallbackMessage
        : switch (progress!.phase) {
            BackupProgressPhase.preparing => 'Dateien werden vorbereitet',
            BackupProgressPhase.encrypting => 'Backup wird verschlüsselt',
            BackupProgressPhase.packaging => 'Backup wird abgeschlossen',
            BackupProgressPhase.complete => 'Backup ist bereit',
          };
    final detail = progress == null
        ? 'Bitte einen Moment warten.'
        : progress!.totalItems <= 0
        ? 'Fotos und PDF-Nachweise werden zusammengestellt.'
        : '${progress!.completedItems} von ${progress!.totalItems} Dateien';

    return ColoredBox(
      color: colors.surface.withValues(alpha: 0.94),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              key: const ValueKey('backup-progress-overlay'),
              elevation: 2,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            progress?.phase == BackupProgressPhase.complete
                                ? Icons.check_rounded
                                : Icons.shield_outlined,
                            size: 30,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          title,
                          key: ValueKey(title),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detail,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          key: const ValueKey('backup-linear-progress'),
                          value: value,
                          minHeight: 8,
                        ),
                      ),
                      if (value != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${(value * 100).round()} %',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
