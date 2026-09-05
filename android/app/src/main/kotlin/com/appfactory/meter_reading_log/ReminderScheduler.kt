package com.appfactory.meter_reading_log

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat

internal object ReminderScheduler {
    private const val fireAction =
        "com.appfactory.meter_reading_log.FIRE_METER_REMINDER"

    fun scheduleNext(context: Context, reminder: StoredReminder) {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val triggerAt = reminder.nextTriggerAfter(System.currentTimeMillis())
        val operation = firePendingIntent(context, reminder.meterId, false) ?: return
        if (reminder.isPunctual && canScheduleExact(context)) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    operation,
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, operation)
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAt,
                operation,
            )
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, operation)
        }
    }

    fun cancelPending(context: Context, meterId: String) {
        val operation = firePendingIntent(context, meterId, true) ?: return
        context.getSystemService(AlarmManager::class.java).cancel(operation)
        operation.cancel()
    }

    fun rescheduleAll(context: Context) {
        ReminderStore.all(context).forEach { reminder ->
            cancelPending(context, reminder.meterId)
            scheduleNext(context, reminder)
        }
    }

    fun canScheduleExact(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return context.getSystemService(AlarmManager::class.java)
            .canScheduleExactAlarms()
    }

    private fun firePendingIntent(
        context: Context,
        meterId: String,
        onlyIfExisting: Boolean,
    ): PendingIntent? {
        val intent = Intent(context, MeterReminderReceiver::class.java)
            .setAction(fireAction)
            .setData(
                Uri.Builder()
                    .scheme("meter-reading-log")
                    .authority("reminder")
                    .appendPath(meterId)
                    .build(),
            )
            .putExtra("meter_id", meterId)
        var flags = PendingIntent.FLAG_IMMUTABLE
        flags = flags or if (onlyIfExisting) {
            PendingIntent.FLAG_NO_CREATE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getBroadcast(
            context,
            stableRequestCode(meterId, 0),
            intent,
            flags,
        )
    }
}

internal object ReminderNotifier {
    private const val normalChannelId = "meter_reading_reminders"
    private const val alarmChannelId = "meter_reading_alarm_reminders_v1"
    private const val meterNotificationId = 1001
    private const val testNotificationId = 2001
    private const val meterTagPrefix = "meter:"
    private const val testTag = "reminder:test"

    fun notificationsEnabled(context: Context): Boolean {
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.N ||
            manager.areNotificationsEnabled()
    }

    fun showMeter(
        context: Context,
        reminder: StoredReminder,
        postedAt: Long = System.currentTimeMillis(),
    ): Long? {
        if (!notificationsEnabled(context)) return null
        ensureChannels(context)
        val channelId = if (reminder.isPunctual) alarmChannelId else normalChannelId
        val category = if (reminder.isPunctual) {
            NotificationCompat.CATEGORY_ALARM
        } else {
            NotificationCompat.CATEGORY_REMINDER
        }
        val latestReading = if (
            !reminder.latestValue.isNullOrBlank() &&
            !reminder.latestUnit.isNullOrBlank()
        ) {
            "Letzter Stand: ${reminder.latestValue} ${reminder.latestUnit}"
        } else {
            "Noch keine Ablesung"
        }
        val summary = "${reminder.meterTypeLabel} · $latestReading"
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(notificationIcon(reminder.meterType))
            .setContentTitle("${reminder.meterTypeLabel} · ${reminder.label}")
            .setContentText(summary)
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    "$latestReading\nJetzt ablesen oder fotografieren und den Verlauf aktualisieren.",
                ),
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(category)
            .setAutoCancel(true)
            .setWhen(postedAt)
            .setShowWhen(true)
            .setContentIntent(openMeterIntent(context, reminder.meterId))
            .build()
        context.getSystemService(NotificationManager::class.java).notify(
            meterTag(reminder.meterId),
            meterNotificationId,
            notification,
        )
        return postedAt
    }

    private fun notificationIcon(meterType: String): Int = when (meterType) {
        "electricity" -> R.drawable.ic_stat_meter
        "electricityFeedIn" -> R.drawable.ic_stat_solar
        "gas" -> R.drawable.ic_stat_gas
        "water" -> R.drawable.ic_stat_water
        "coldWater" -> R.drawable.ic_stat_cold_water
        "hotWater" -> R.drawable.ic_stat_hot_water
        "heat" -> R.drawable.ic_stat_heat
        "heatingCostAllocator" -> R.drawable.ic_stat_home
        "oil" -> R.drawable.ic_stat_oil
        else -> R.drawable.ic_stat_other
    }

    fun migrateLegacyNotification(context: Context, reminder: StoredReminder) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val manager = context.getSystemService(NotificationManager::class.java)
        val legacy = manager.activeNotifications.firstOrNull { notification ->
            notification.tag == null &&
                notification.id == stableRequestCode(reminder.meterId, 0)
        } ?: return
        manager.cancel(legacy.id)
        if (showMeter(context, reminder, legacy.postTime) != null) {
            ReminderStore.setLastTriggered(
                context,
                reminder.meterId,
                legacy.postTime,
            )
        }
    }

    fun showTest(context: Context) {
        if (!notificationsEnabled(context)) return
        ensureChannels(context)
        val notification = NotificationCompat.Builder(context, alarmChannelId)
            .setSmallIcon(R.drawable.ic_stat_meter)
            .setContentTitle("Test-Erinnerung")
            .setContentText("So klingt „Pünktlich mit Ton“.")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setTimeoutAfter(10_000L)
            .build()
        context.getSystemService(NotificationManager::class.java).notify(
            testTag,
            testNotificationId,
            notification,
        )
    }

    fun acknowledge(context: Context, meterId: String) {
        context.getSystemService(NotificationManager::class.java)
            .cancel(meterTag(meterId), meterNotificationId)
    }

    fun activeMeterIds(context: Context): Set<String> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return emptySet()
        return context.getSystemService(NotificationManager::class.java)
            .activeNotifications
            .mapNotNull { notification ->
                notification.tag
                    ?.takeIf { it.startsWith(meterTagPrefix) }
                    ?.removePrefix(meterTagPrefix)
            }
            .toSet()
    }

    private fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        val normal = NotificationChannel(
            normalChannelId,
            "Zählerablesungen",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Optionale Erinnerungen für regelmäßige Zählerablesungen."
            enableVibration(true)
            setSound(
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
        }
        val alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val alarm = NotificationChannel(
            alarmChannelId,
            "Pünktliche Zählerablesungen",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Pünktliche Ableseerinnerungen mit Alarmton."
            enableVibration(true)
            setSound(
                alarmSound,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build(),
            )
        }
        manager.createNotificationChannels(listOf(normal, alarm))
    }

    private fun openMeterIntent(context: Context, meterId: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction("com.appfactory.meter_reading_log.OPEN_METER")
            .putExtra("meter_id", meterId)
            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(
            context,
            stableRequestCode(meterId, 1),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun meterTag(meterId: String) = meterTagPrefix + meterId
}

internal fun stableRequestCode(value: String, salt: Int): Int {
    var hash = 0x811c9dc5L
    value.forEach { character ->
        hash = hash xor character.code.toLong()
        hash = (hash * 0x01000193L) and 0x7fffffffL
    }
    return ((hash + salt) and 0x7fffffffL).toInt().coerceAtLeast(1)
}
