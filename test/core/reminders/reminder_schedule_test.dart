import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/reminders/local_notification_reminder_repository.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';

void main() {
  group('hourly reminders anchored to their selected start', () {
    final start = DateTime.utc(2026, 9, 15, 12, 30);
    final schedule = ReadingReminderSchedule(
      interval: ReminderInterval.hourly,
      day: 1,
      hour: 14,
      minute: 30,
      startsAt: start,
    );

    test('waits until the start and advances strictly beyond now', () {
      expect(
        nextReminderDate(
          schedule,
          start.subtract(const Duration(days: 3)),
        ).toUtc(),
        start,
      );
      expect(
        nextReminderDate(schedule, start).toUtc(),
        start.add(const Duration(hours: 1)),
      );
      expect(
        nextReminderDate(
          schedule,
          start.add(const Duration(minutes: 59, seconds: 59)),
        ).toUtc(),
        start.add(const Duration(hours: 1)),
      );
    });

    test(
      'delays and restarts skip missed hours without shifting the anchor',
      () {
        final delayed = start.add(
          const Duration(days: 5, hours: 7, minutes: 23),
        );
        expect(
          nextReminderDate(schedule, delayed).toUtc(),
          start.add(const Duration(days: 5, hours: 8)),
        );
        final restored = ReadingReminderSchedule.fromJson(schedule.toJson());
        expect(restored.startsAt, start);
        expect(
          nextReminderDate(restored, delayed),
          nextReminderDate(schedule, delayed),
        );
      },
    );

    test('hourly starts serialize to UTC and survive local conversion', () {
      final restored = ReadingReminderSchedule.fromJson({
        ...schedule.toJson(),
        'startsAt': '2026-09-15T14:30:00+02:00',
      });
      expect(restored.startsAt, start);
      expect(restored.toJson()['startsAt'], start.toIso8601String());
    });

    test(
      'missing hourly anchor is rejected, old daily schedules still load',
      () {
        final json = schedule.toJson()..remove('startsAt');
        expect(
          () => ReadingReminderSchedule.fromJson(json),
          throwsFormatException,
        );
        final old = ReadingReminderSchedule.fromJson({
          ...json,
          'interval': 'daily',
        });
        expect(old.startsAt, isNull);
        expect(old.interval, ReminderInterval.daily);
      },
    );

    for (final startText in [
      '2026-03-29T01:30:00+01:00',
      '2026-10-25T02:30:00+02:00',
    ]) {
      test(
        'keeps 60 elapsed minutes over daylight saving change $startText',
        () {
          final anchor = DateTime.parse(startText);
          final dstSchedule = ReadingReminderSchedule(
            interval: ReminderInterval.hourly,
            day: 1,
            hour: 0,
            minute: 30,
            startsAt: anchor,
          );
          var current = anchor;
          for (var index = 0; index < 5; index++) {
            final next = nextReminderDate(dstSchedule, current).toUtc();
            expect(next.difference(current), const Duration(hours: 1));
            current = next;
          }
        },
      );
    }
  });

  test('minutely dev reminder advances to the next full minute', () {
    const schedule = ReadingReminderSchedule(
      interval: ReminderInterval.minutely,
      day: 1,
      hour: 9,
      minute: 30,
    );

    expect(
      nextReminderDate(schedule, DateTime(2026, 9, 4, 8, 17, 42, 500)),
      DateTime(2026, 9, 4, 8, 18),
    );
  });

  test('daily reminder uses today or advances to tomorrow', () {
    const schedule = ReadingReminderSchedule(
      interval: ReminderInterval.daily,
      day: 1,
      hour: 9,
      minute: 30,
    );

    expect(
      nextReminderDate(schedule, DateTime(2026, 9, 4, 8)),
      DateTime(2026, 9, 4, 9, 30),
    );
    expect(
      nextReminderDate(schedule, DateTime(2026, 9, 4, 10)),
      DateTime(2026, 9, 5, 9, 30),
    );
  });

  test('weekly reminder uses weekday and advances by a week when passed', () {
    const schedule = ReadingReminderSchedule(
      interval: ReminderInterval.weekly,
      day: DateTime.friday,
      hour: 9,
      minute: 30,
    );

    expect(
      nextReminderDate(schedule, DateTime(2026, 9, 3, 10)),
      DateTime(2026, 9, 4, 9, 30),
    );
    expect(
      nextReminderDate(schedule, DateTime(2026, 9, 4, 10)),
      DateTime(2026, 9, 11, 9, 30),
    );
  });

  test('monthly reminder advances to next month when date passed', () {
    const schedule = ReadingReminderSchedule(
      interval: ReminderInterval.monthly,
      day: 15,
      hour: 9,
      minute: 30,
    );

    expect(
      nextReminderDate(schedule, DateTime(2026, 8, 20, 12)),
      DateTime(2026, 9, 15, 9, 30),
    );
  });

  test('yearly reminder clamps February day', () {
    const schedule = ReadingReminderSchedule(
      interval: ReminderInterval.yearly,
      month: 2,
      day: 31,
      hour: 9,
      minute: 0,
    );

    expect(
      nextReminderDate(schedule, DateTime(2026, 1, 1)),
      DateTime(2026, 2, 28, 9),
    );
  });

  test('old schedules default to a normal reminder', () {
    final schedule = ReadingReminderSchedule.fromJson(const {
      'interval': 'daily',
      'day': 1,
      'hour': 9,
      'minute': 30,
      'month': null,
    });

    expect(schedule.deliveryMode, ReminderDeliveryMode.normal);
  });

  test('punctual reminder mode survives serialization', () {
    const schedule = ReadingReminderSchedule(
      interval: ReminderInterval.weekly,
      day: DateTime.friday,
      hour: 9,
      minute: 30,
      deliveryMode: ReminderDeliveryMode.punctualWithSound,
    );

    expect(
      ReadingReminderSchedule.fromJson(schedule.toJson()).deliveryMode,
      ReminderDeliveryMode.punctualWithSound,
    );
  });
}
