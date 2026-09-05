import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/reminders/local_notification_reminder_repository.dart';
import 'app_router.dart';
import 'app_providers.dart';
import 'app_theme.dart';

class MeterReadingLogApp extends ConsumerStatefulWidget {
  const MeterReadingLogApp({super.key});

  @override
  ConsumerState<MeterReadingLogApp> createState() => _MeterReadingLogAppState();
}

class _MeterReadingLogAppState extends ConsumerState<MeterReadingLogApp> {
  late final StreamSubscription<String> _notificationSubscription;

  @override
  void initState() {
    super.initState();
    final reminders = ref.read(meterReminderRepositoryProvider);
    _notificationSubscription = reminders.notificationOpened.listen(_openMeter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_synchronizeReminders(reminders));
      unawaited(_openInitialNotification(reminders));
    });
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  Future<void> _openInitialNotification(
    MeterReminderRepository reminders,
  ) async {
    final meterId = await reminders.consumeInitialMeterId();
    if (mounted && meterId != null) _openMeter(meterId);
  }

  Future<void> _synchronizeReminders(MeterReminderRepository reminders) async {
    final meters = await ref.read(meterRepositoryProvider).loadAll();
    for (final meter in meters) {
      if (meter.reminder != null) await reminders.schedule(meter);
    }
  }

  void _openMeter(String meterId) {
    ref
        .read(appRouterProvider)
        .goNamed('meterDetail', pathParameters: {'id': meterId});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZählerstandLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
