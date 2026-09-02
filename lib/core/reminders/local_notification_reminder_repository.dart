import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/meters/domain/meter.dart';

enum ReminderPermissionStatus { granted, denied, unknown, unsupported }

abstract interface class MeterReminderRepository {
  Future<void> schedule(Meter meter);

  Future<void> cancel(String meterId);
}

class LocalNotificationReminderRepository implements MeterReminderRepository {
  LocalNotificationReminderRepository._();

  static final instance = LocalNotificationReminderRepository._();

  static const _icon = 'ic_stat_meter';
  static const _channelId = 'meter_reading_reminders';
  static const _channelName = 'Zählerablesungen';
  static const _channelDescription =
      'Optionale Erinnerungen für regelmäßige Zählerablesungen.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
    if (!_supportsNotifications) {
      return;
    }
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_icon),
        ),
      );
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    } on Object {
      return;
    }
  }

  Future<ReminderPermissionStatus> permissionStatus() async {
    await initialize();
    if (!_supportsNotifications) {
      return ReminderPermissionStatus.unsupported;
    }
    try {
      final enabled = await _androidPlugin()?.areNotificationsEnabled();
      return switch (enabled) {
        true => ReminderPermissionStatus.granted,
        false => ReminderPermissionStatus.denied,
        null => ReminderPermissionStatus.unknown,
      };
    } on Object {
      return ReminderPermissionStatus.unknown;
    }
  }

  Future<ReminderPermissionStatus> requestPermission() async {
    await initialize();
    if (!_supportsNotifications) {
      return ReminderPermissionStatus.unsupported;
    }
    try {
      final granted = await _androidPlugin()?.requestNotificationsPermission();
      return granted == true
          ? ReminderPermissionStatus.granted
          : ReminderPermissionStatus.denied;
    } on Object {
      return ReminderPermissionStatus.unknown;
    }
  }

  @override
  Future<void> schedule(Meter meter) async {
    await initialize();
    await cancel(meter.id);
    final schedule = meter.reminder;
    if (schedule == null || !_supportsNotifications) {
      return;
    }
    var permission = await permissionStatus();
    if (permission != ReminderPermissionStatus.granted) {
      permission = await requestPermission();
    }
    if (permission != ReminderPermissionStatus.granted) {
      return;
    }

    final next = nextReminderDate(schedule, DateTime.now());
    final components = schedule.interval == ReminderInterval.monthly
        ? DateTimeComponents.dayOfMonthAndTime
        : DateTimeComponents.dateAndTime;
    try {
      await _plugin.zonedSchedule(
        id: stableNotificationId(meter.id),
        title: '${meter.label} ablesen',
        body: 'Jetzt Zählerstand fotografieren und Verlauf aktualisieren.',
        scheduledDate: tz.TZDateTime.from(next, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            icon: _icon,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'meter:${meter.id}',
        matchDateTimeComponents: components,
      );
    } on Object {
      return;
    }
  }

  @override
  Future<void> cancel(String meterId) async {
    if (!_supportsNotifications) {
      return;
    }
    try {
      await _plugin.cancel(id: stableNotificationId(meterId));
    } on Object {
      return;
    }
  }

  AndroidFlutterLocalNotificationsPlugin? _androidPlugin() {
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  bool get _supportsNotifications =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

DateTime nextReminderDate(ReadingReminderSchedule schedule, DateTime now) {
  if (schedule.interval == ReminderInterval.monthly) {
    var year = now.year;
    var month = now.month;
    var candidate = _safeDate(
      year,
      month,
      schedule.day,
      schedule.hour,
      schedule.minute,
    );
    if (!candidate.isAfter(now)) {
      month += 1;
      if (month == 13) {
        month = 1;
        year += 1;
      }
      candidate = _safeDate(
        year,
        month,
        schedule.day,
        schedule.hour,
        schedule.minute,
      );
    }
    return candidate;
  }

  final month = schedule.month ?? now.month;
  var candidate = _safeDate(
    now.year,
    month,
    schedule.day,
    schedule.hour,
    schedule.minute,
  );
  if (!candidate.isAfter(now)) {
    candidate = _safeDate(
      now.year + 1,
      month,
      schedule.day,
      schedule.hour,
      schedule.minute,
    );
  }
  return candidate;
}

DateTime _safeDate(int year, int month, int day, int hour, int minute) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day.clamp(1, lastDay), hour, minute);
}

int stableNotificationId(String value) {
  const prime = 0x01000193;
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * prime) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}
