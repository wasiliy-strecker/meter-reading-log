import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/reminders/local_notification_reminder_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationReminderRepository.instance.initialize();
  runApp(const ProviderScope(child: MeterReadingLogApp()));
}
