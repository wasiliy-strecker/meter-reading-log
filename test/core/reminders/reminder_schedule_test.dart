import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:meter_reading_log/core/reminders/local_notification_reminder_repository.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';

void main() {
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

  test('maps every interval to the matching recurring date components', () {
    expect(
      reminderDateTimeComponents(ReminderInterval.daily),
      DateTimeComponents.time,
    );
    expect(
      reminderDateTimeComponents(ReminderInterval.weekly),
      DateTimeComponents.dayOfWeekAndTime,
    );
    expect(
      reminderDateTimeComponents(ReminderInterval.monthly),
      DateTimeComponents.dayOfMonthAndTime,
    );
    expect(
      reminderDateTimeComponents(ReminderInterval.yearly),
      DateTimeComponents.dateAndTime,
    );
  });
}
