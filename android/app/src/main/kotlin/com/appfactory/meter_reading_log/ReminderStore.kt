package com.appfactory.meter_reading_log

import android.content.Context
import org.json.JSONObject
import java.time.DayOfWeek
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.YearMonth
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.temporal.TemporalAdjusters

internal const val REMINDER_STATUS_CHANGED =
    "com.appfactory.meter_reading_log.REMINDER_STATUS_CHANGED"

internal data class StoredReminder(
    val meterId: String,
    val label: String,
    val meterTypeLabel: String,
    val latestValue: String?,
    val latestUnit: String?,
    val interval: String,
    val day: Int,
    val month: Int?,
    val hour: Int,
    val minute: Int,
    val deliveryMode: String,
) {
    val isPunctual: Boolean
        get() = deliveryMode == "punctualWithSound"

    fun toJson(): String = JSONObject()
        .put("meterId", meterId)
        .put("label", label)
        .put("meterTypeLabel", meterTypeLabel)
        .put("latestValue", latestValue)
        .put("latestUnit", latestUnit)
        .put("interval", interval)
        .put("day", day)
        .put("month", month)
        .put("hour", hour)
        .put("minute", minute)
        .put("deliveryMode", deliveryMode)
        .toString()

    fun nextTriggerAfter(
        nowMillis: Long,
        zoneId: ZoneId = ZoneId.systemDefault(),
    ): Long {
        val now = Instant.ofEpochMilli(nowMillis).atZone(zoneId)
        val time = LocalTime.of(hour.coerceIn(0, 23), minute.coerceIn(0, 59))
        val candidate = when (interval) {
            "minutely" -> if (BuildConfig.DEBUG) {
                nextMinutely(now)
            } else {
                nextDaily(now, time, zoneId)
            }
            "daily" -> nextDaily(now, time, zoneId)
            "weekly" -> nextWeekly(now, time, zoneId)
            "yearly" -> nextYearly(now, time, zoneId)
            else -> nextMonthly(now, time, zoneId)
        }
        return candidate.toInstant().toEpochMilli()
    }

    private fun nextMinutely(now: ZonedDateTime): ZonedDateTime =
        now.withSecond(0).withNano(0).plusMinutes(1)

    private fun nextDaily(
        now: ZonedDateTime,
        time: LocalTime,
        zoneId: ZoneId,
    ): ZonedDateTime {
        var date = now.toLocalDate()
        var candidate = atLocal(date, time, zoneId)
        if (!candidate.isAfter(now)) {
            date = date.plusDays(1)
            candidate = atLocal(date, time, zoneId)
        }
        return candidate
    }

    private fun nextWeekly(
        now: ZonedDateTime,
        time: LocalTime,
        zoneId: ZoneId,
    ): ZonedDateTime {
        val weekday = DayOfWeek.of(day.coerceIn(1, 7))
        var date = now.toLocalDate().with(TemporalAdjusters.nextOrSame(weekday))
        var candidate = atLocal(date, time, zoneId)
        if (!candidate.isAfter(now)) {
            date = date.plusWeeks(1)
            candidate = atLocal(date, time, zoneId)
        }
        return candidate
    }

    private fun nextMonthly(
        now: ZonedDateTime,
        time: LocalTime,
        zoneId: ZoneId,
    ): ZonedDateTime {
        var yearMonth = YearMonth.from(now)
        var date = safeDate(yearMonth)
        var candidate = atLocal(date, time, zoneId)
        if (!candidate.isAfter(now)) {
            yearMonth = yearMonth.plusMonths(1)
            date = safeDate(yearMonth)
            candidate = atLocal(date, time, zoneId)
        }
        return candidate
    }

    private fun nextYearly(
        now: ZonedDateTime,
        time: LocalTime,
        zoneId: ZoneId,
    ): ZonedDateTime {
        val safeMonth = (month ?: 1).coerceIn(1, 12)
        var year = now.year
        var date = safeDate(YearMonth.of(year, safeMonth))
        var candidate = atLocal(date, time, zoneId)
        if (!candidate.isAfter(now)) {
            year += 1
            date = safeDate(YearMonth.of(year, safeMonth))
            candidate = atLocal(date, time, zoneId)
        }
        return candidate
    }

    private fun safeDate(yearMonth: YearMonth): LocalDate =
        yearMonth.atDay(day.coerceIn(1, yearMonth.lengthOfMonth()))

    private fun atLocal(
        date: LocalDate,
        time: LocalTime,
        zoneId: ZoneId,
    ): ZonedDateTime = ZonedDateTime.of(date, time, zoneId)

    companion object {
        fun fromJson(value: String): StoredReminder? = try {
            val json = JSONObject(value)
            StoredReminder(
                meterId = json.getString("meterId"),
                label = json.getString("label"),
                meterTypeLabel = json.optString("meterTypeLabel", "Zähler"),
                latestValue = json.optString("latestValue", "")
                    .takeIf { it.isNotBlank() },
                latestUnit = json.optString("latestUnit", "")
                    .takeIf { it.isNotBlank() },
                interval = json.getString("interval"),
                day = json.getInt("day"),
                month = if (json.isNull("month")) null else json.getInt("month"),
                hour = json.getInt("hour"),
                minute = json.getInt("minute"),
                deliveryMode = json.optString("deliveryMode", "normal"),
            )
        } catch (_: Exception) {
            null
        }
    }
}

internal object ReminderStore {
    private const val preferencesName = "meter_reminder_state"
    private const val schedulePrefix = "schedule:"
    private const val lastTriggeredPrefix = "last_triggered:"

    private fun preferences(context: Context) =
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

    fun save(context: Context, reminder: StoredReminder) {
        preferences(context).edit()
            .putString(schedulePrefix + reminder.meterId, reminder.toJson())
            .apply()
    }

    fun find(context: Context, meterId: String): StoredReminder? {
        val value = preferences(context).getString(schedulePrefix + meterId, null)
            ?: return null
        return StoredReminder.fromJson(value)
    }

    fun all(context: Context): List<StoredReminder> = preferences(context).all
        .filterKeys { it.startsWith(schedulePrefix) }
        .values
        .mapNotNull { value -> (value as? String)?.let(StoredReminder::fromJson) }

    fun remove(context: Context, meterId: String) {
        preferences(context).edit()
            .remove(schedulePrefix + meterId)
            .remove(lastTriggeredPrefix + meterId)
            .apply()
    }

    fun setLastTriggered(context: Context, meterId: String, timestamp: Long) {
        preferences(context).edit()
            .putLong(lastTriggeredPrefix + meterId, timestamp)
            .apply()
    }

    fun lastTriggered(context: Context, meterId: String): Long? {
        val key = lastTriggeredPrefix + meterId
        val values = preferences(context)
        return if (values.contains(key)) values.getLong(key, 0L) else null
    }
}
