package com.appfactory.meter_reading_log

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class MeterReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val meterId = intent.getStringExtra("meter_id") ?: return
        val reminder = ReminderStore.find(context, meterId) ?: return
        val postedAt = ReminderNotifier.showMeter(context, reminder)
        if (postedAt != null) {
            ReminderStore.setLastTriggered(context, meterId, postedAt)
            context.sendBroadcast(
                Intent(REMINDER_STATUS_CHANGED).setPackage(context.packageName),
            )
        }
        ReminderScheduler.scheduleNext(context, reminder)
    }
}

class ReminderRescheduleReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        ReminderScheduler.rescheduleAll(context)
    }
}
