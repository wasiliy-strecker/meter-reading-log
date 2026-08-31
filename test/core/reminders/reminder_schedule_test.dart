import 'package:flutter_test/flutter_test.dart';
import 'package:meter_reading_log/core/reminders/local_notification_reminder_repository.dart';
import 'package:meter_reading_log/features/meters/domain/meter.dart';

void main() {
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
}
