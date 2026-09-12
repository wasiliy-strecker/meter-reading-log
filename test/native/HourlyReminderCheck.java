import com.appfactory.meter_reading_log.StoredReminder;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;

/**
 * Dependency-free JVM regression check against the actual Dev Kotlin classes.
 * After building Dev, run with the Kotlin output directory and kotlin-stdlib
 * on the Java classpath: java -cp <classes>:<stdlib.jar> this-file.java
 */
class HourlyReminderCheck {
    private static StoredReminder reminder(Long start) {
        return new StoredReminder("meter", "Synthetic meter", "electricity",
                "Strom", null, null, "hourly", 1, null, 14, 30, "normal", start);
    }

    private static void equal(long actual, long expected) {
        if (actual != expected) {
            throw new AssertionError("Expected " + expected + ", received " + actual);
        }
    }

    public static void main(String[] args) {
        long start = Instant.parse("2026-09-15T12:30:00Z").toEpochMilli();
        long hour = Duration.ofHours(1).toMillis();
        ZoneId berlin = ZoneId.of("Europe/Berlin");
        StoredReminder schedule = reminder(start);
        equal(schedule.nextTriggerAfter(start - 1, berlin), start);
        equal(schedule.nextTriggerAfter(start, berlin), start + hour);
        equal(schedule.nextTriggerAfter(start + hour - 1, berlin), start + hour);
        equal(schedule.nextTriggerAfter(start + 127 * hour + 23000, berlin), start + 128 * hour);
        // A reconstructed schedule (restart) retains the original anchor.
        equal(reminder(start).nextTriggerAfter(start + 127 * hour + 23000, berlin), start + 128 * hour);
        for (String timestamp : new String[]{"2026-03-29T00:30:00Z", "2026-10-25T00:30:00Z"}) {
            long anchor = Instant.parse(timestamp).toEpochMilli();
            StoredReminder dst = reminder(anchor);
            for (int i = 0; i < 5; i++) {
                equal(dst.nextTriggerAfter(anchor + i * hour, berlin), anchor + (i + 1) * hour);
            }
        }
        try {
            reminder(null).nextTriggerAfter(start, berlin);
            throw new AssertionError("Missing hourly anchor was accepted");
        } catch (IllegalArgumentException expected) {
            // Invalid schedules must never become monthly reminders.
        }
        System.out.println("Hourly Android scheduling: 16 checks passed");
    }
}
