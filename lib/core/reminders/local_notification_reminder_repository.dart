import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/meters/domain/meter.dart';
import '../../features/meters/domain/meter_reading.dart';

enum ReminderPermissionStatus { granted, denied, unknown, unsupported }

class ReminderStatus {
  const ReminderStatus({
    required this.meterId,
    required this.isNotificationActive,
    this.lastTriggeredAt,
  });

  final String meterId;
  final bool isNotificationActive;
  final DateTime? lastTriggeredAt;
}

class MeterReminderTestRequest {
  const MeterReminderTestRequest({
    required this.label,
    required this.meterType,
    required this.deliveryMode,
    this.meterId,
    this.latestValue,
    this.latestUnit,
  });

  final String label;
  final MeterType meterType;
  final ReminderDeliveryMode deliveryMode;
  final String? meterId;
  final String? latestValue;
  final String? latestUnit;
}

abstract interface class MeterReminderRepository {
  Stream<int> get statusChanges;

  Stream<String> get notificationOpened;

  Future<void> initialize();

  Future<ReminderPermissionStatus> permissionStatus();

  Future<ReminderPermissionStatus> requestPermission();

  Future<bool> canScheduleExactAlarms();

  Future<bool> requestExactAlarmPermission();

  Future<bool> openExactAlarmSettings();

  Future<void> schedule(Meter meter, {MeterReading? latestReading});

  Future<void> cancel(String meterId);

  Future<void> acknowledge(String meterId);

  Future<Map<String, ReminderStatus>> loadStatuses(Iterable<String> meterIds);

  Future<bool> showReminderTest(MeterReminderTestRequest request);

  Future<String?> consumeInitialMeterId();

  void refreshStatuses();
}

class LocalNotificationReminderRepository implements MeterReminderRepository {
  LocalNotificationReminderRepository._();

  static final instance = LocalNotificationReminderRepository._();
  static const _channel = MethodChannel(
    'com.appfactory.meter_reading_log/reminders',
  );

  final _statusChanges = StreamController<int>.broadcast();
  final _notificationOpened = StreamController<String>.broadcast();
  int _statusRevision = 0;
  bool _initialized = false;

  @override
  Stream<int> get statusChanges => _statusChanges.stream;

  @override
  Stream<String> get notificationOpened => _notificationOpened.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!_supportsNotifications) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'statusChanged') {
        refreshStatuses();
      } else if (call.method == 'notificationOpened') {
        final meterId = call.arguments as String?;
        if (meterId != null && meterId.isNotEmpty) {
          _notificationOpened.add(meterId);
          refreshStatuses();
        }
      }
    });
  }

  @override
  Future<ReminderPermissionStatus> permissionStatus() async {
    await initialize();
    if (!_supportsNotifications) return ReminderPermissionStatus.unsupported;
    try {
      final enabled = await _channel.invokeMethod<bool>(
        'areNotificationsEnabled',
      );
      return switch (enabled) {
        true => ReminderPermissionStatus.granted,
        false => ReminderPermissionStatus.denied,
        null => ReminderPermissionStatus.unknown,
      };
    } on Object {
      return ReminderPermissionStatus.unknown;
    }
  }

  @override
  Future<ReminderPermissionStatus> requestPermission() async {
    await initialize();
    if (!_supportsNotifications) return ReminderPermissionStatus.unsupported;
    try {
      final granted = await _channel.invokeMethod<bool>(
        'requestNotificationPermission',
      );
      return granted == true
          ? ReminderPermissionStatus.granted
          : ReminderPermissionStatus.denied;
    } on Object {
      return ReminderPermissionStatus.unknown;
    }
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    await initialize();
    if (!_supportsNotifications) return false;
    try {
      return await _channel.invokeMethod<bool>('canScheduleExactAlarms') ??
          false;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    await initialize();
    if (!_supportsNotifications) return false;
    try {
      return await _channel.invokeMethod<bool>('requestExactAlarmPermission') ??
          false;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> openExactAlarmSettings() async {
    await initialize();
    if (!_supportsNotifications) return false;
    try {
      return await _channel.invokeMethod<bool>('openExactAlarmSettings') ??
          false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> schedule(Meter meter, {MeterReading? latestReading}) async {
    await initialize();
    final schedule = meter.reminder;
    if (schedule == null) {
      await cancel(meter.id);
      return;
    }
    if (!_supportsNotifications) return;
    var permission = await permissionStatus();
    if (permission != ReminderPermissionStatus.granted) {
      permission = await requestPermission();
    }
    if (permission != ReminderPermissionStatus.granted) return;
    try {
      await _channel.invokeMethod<void>('schedule', {
        'meterId': meter.id,
        'label': meter.label,
        'meterType': meter.type.wireName,
        'meterTypeLabel': meter.type.label,
        'latestValue': latestReading?.value.displayText,
        'latestUnit': latestReading?.meter.unit,
        'interval': schedule.interval.name,
        'day': schedule.day,
        'month': schedule.month,
        'hour': schedule.hour,
        'minute': schedule.minute,
        'deliveryMode': schedule.deliveryMode.name,
      });
      refreshStatuses();
    } on Object {
      return;
    }
  }

  @override
  Future<void> cancel(String meterId) async {
    await initialize();
    if (!_supportsNotifications) return;
    try {
      await _channel.invokeMethod<void>('cancel', {'meterId': meterId});
      refreshStatuses();
    } on Object {
      return;
    }
  }

  @override
  Future<void> acknowledge(String meterId) async {
    await initialize();
    if (!_supportsNotifications) return;
    try {
      await _channel.invokeMethod<void>('acknowledge', {'meterId': meterId});
      refreshStatuses();
    } on Object {
      return;
    }
  }

  @override
  Future<Map<String, ReminderStatus>> loadStatuses(
    Iterable<String> meterIds,
  ) async {
    await initialize();
    final ids = meterIds.toList(growable: false);
    if (!_supportsNotifications || ids.isEmpty) return const {};
    try {
      final result = await _channel.invokeListMethod<Object?>('getStatuses', {
        'meterIds': ids,
      });
      final statuses = <String, ReminderStatus>{};
      for (final raw in result ?? const []) {
        if (raw is! Map) continue;
        final values = Map<Object?, Object?>.from(raw);
        final meterId = values['meterId'] as String?;
        if (meterId == null) continue;
        final lastTriggeredMillis = values['lastTriggeredAtMillis'] as int?;
        statuses[meterId] = ReminderStatus(
          meterId: meterId,
          isNotificationActive:
              values['isNotificationActive'] as bool? ?? false,
          lastTriggeredAt: lastTriggeredMillis == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  lastTriggeredMillis,
                  isUtc: true,
                ),
        );
      }
      return statuses;
    } on Object {
      return const {};
    }
  }

  @override
  Future<bool> showReminderTest(MeterReminderTestRequest request) async {
    await initialize();
    if (!_supportsNotifications) return false;
    var permission = await permissionStatus();
    if (permission != ReminderPermissionStatus.granted) {
      permission = await requestPermission();
    }
    if (permission != ReminderPermissionStatus.granted) return false;
    try {
      return await _channel.invokeMethod<bool>('showReminderTest', {
            'meterId': request.meterId,
            'label': request.label,
            'meterType': request.meterType.wireName,
            'meterTypeLabel': request.meterType.label,
            'latestValue': request.latestValue,
            'latestUnit': request.latestUnit,
            'deliveryMode': request.deliveryMode.name,
          }) ??
          false;
    } on Object {
      return false;
    }
  }

  @override
  Future<String?> consumeInitialMeterId() async {
    await initialize();
    if (!_supportsNotifications) return null;
    try {
      return await _channel.invokeMethod<String>('consumeInitialMeterId');
    } on Object {
      return null;
    }
  }

  @override
  void refreshStatuses() {
    if (!_statusChanges.isClosed) _statusChanges.add(++_statusRevision);
  }

  bool get _supportsNotifications =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

DateTime nextReminderDate(ReadingReminderSchedule schedule, DateTime now) {
  if (schedule.interval == ReminderInterval.minutely) {
    return DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));
  }

  if (schedule.interval == ReminderInterval.daily) {
    var candidate = DateTime(
      now.year,
      now.month,
      now.day,
      schedule.hour,
      schedule.minute,
    );
    if (!candidate.isAfter(now)) {
      candidate = DateTime(
        now.year,
        now.month,
        now.day + 1,
        schedule.hour,
        schedule.minute,
      );
    }
    return candidate;
  }

  if (schedule.interval == ReminderInterval.weekly) {
    final weekday = schedule.day.clamp(DateTime.monday, DateTime.sunday);
    var daysAhead = (weekday - now.weekday) % DateTime.daysPerWeek;
    var candidate = DateTime(
      now.year,
      now.month,
      now.day + daysAhead,
      schedule.hour,
      schedule.minute,
    );
    if (!candidate.isAfter(now)) {
      daysAhead += DateTime.daysPerWeek;
      candidate = DateTime(
        now.year,
        now.month,
        now.day + daysAhead,
        schedule.hour,
        schedule.minute,
      );
    }
    return candidate;
  }

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
