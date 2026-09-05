package com.appfactory.meter_reading_log

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var reminderChannel: MethodChannel? = null
    private var notificationPermissionResult: MethodChannel.Result? = null
    private var statusReceiverRegistered = false

    private val statusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            reminderChannel?.invokeMethod("statusChanged", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        reminderChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.appfactory.meter_reading_log/reminders",
        ).also { channel ->
            channel.setMethodCallHandler(::handleReminderMethod)
        }
    }

    override fun onStart() {
        super.onStart()
        if (!statusReceiverRegistered) {
            val filter = IntentFilter(REMINDER_STATUS_CHANGED)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(statusReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(statusReceiver, filter)
            }
            statusReceiverRegistered = true
        }
    }

    override fun onResume() {
        super.onResume()
        reminderChannel?.invokeMethod("statusChanged", null)
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) reminderChannel?.invokeMethod("statusChanged", null)
    }

    override fun onStop() {
        if (statusReceiverRegistered) {
            unregisterReceiver(statusReceiver)
            statusReceiverRegistered = false
        }
        super.onStop()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        consumeMeterId(intent)?.let { meterId ->
            reminderChannel?.invokeMethod("notificationOpened", meterId)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != notificationPermissionRequestCode) return
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        notificationPermissionResult?.success(granted)
        notificationPermissionResult = null
    }

    private fun handleReminderMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "areNotificationsEnabled" ->
                result.success(ReminderNotifier.notificationsEnabled(this))
            "requestNotificationPermission" -> requestNotificationPermission(result)
            "canScheduleExactAlarms" ->
                result.success(ReminderScheduler.canScheduleExact(this))
            "requestExactAlarmPermission" -> requestExactAlarmPermission(result)
            "schedule" -> schedule(call, result)
            "cancel" -> cancel(call, result)
            "acknowledge" -> acknowledge(call, result)
            "getStatuses" -> getStatuses(call, result)
            "showAlarmTest" -> {
                ReminderNotifier.showTest(this)
                result.success(null)
            }
            "consumeInitialMeterId" -> result.success(consumeMeterId(intent))
            else -> result.notImplemented()
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(ReminderNotifier.notificationsEnabled(this))
            return
        }
        if (
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (notificationPermissionResult != null) {
            result.error("permission_pending", "Die Abfrage läuft bereits.", null)
            return
        }
        notificationPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            notificationPermissionRequestCode,
        )
    }

    private fun requestExactAlarmPermission(result: MethodChannel.Result) {
        if (ReminderScheduler.canScheduleExact(this)) {
            result.success(true)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                startActivity(
                    Intent(
                        Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                        Uri.parse("package:$packageName"),
                    ),
                )
            } catch (_: Exception) {
                startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM))
            }
        }
        result.success(false)
    }

    private fun schedule(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        val meterId = arguments?.get("meterId") as? String
        val label = arguments?.get("label") as? String
        val meterTypeLabel = arguments?.get("meterTypeLabel") as? String
        val interval = arguments?.get("interval") as? String
        val day = arguments?.get("day") as? Int
        val hour = arguments?.get("hour") as? Int
        val minute = arguments?.get("minute") as? Int
        val deliveryMode = arguments?.get("deliveryMode") as? String
        if (
            meterId.isNullOrBlank() || label.isNullOrBlank() ||
            meterTypeLabel.isNullOrBlank() || interval.isNullOrBlank() ||
            day == null || hour == null ||
            minute == null || deliveryMode.isNullOrBlank()
        ) {
            result.error("invalid_schedule", "Erinnerungsdaten sind unvollständig.", null)
            return
        }
        val reminder = StoredReminder(
            meterId = meterId,
            label = label,
            meterTypeLabel = meterTypeLabel,
            latestValue = arguments["latestValue"] as? String,
            latestUnit = arguments["latestUnit"] as? String,
            interval = interval,
            day = day,
            month = arguments["month"] as? Int,
            hour = hour,
            minute = minute,
            deliveryMode = deliveryMode,
        )
        ReminderScheduler.cancelPending(this, meterId)
        ReminderStore.save(this, reminder)
        ReminderNotifier.migrateLegacyNotification(this, reminder)
        ReminderScheduler.scheduleNext(this, reminder)
        result.success(null)
    }

    private fun cancel(call: MethodCall, result: MethodChannel.Result) {
        val meterId = meterIdFrom(call)
        if (meterId == null) {
            result.error("missing_meter", "Zähler-ID fehlt.", null)
            return
        }
        ReminderScheduler.cancelPending(this, meterId)
        ReminderNotifier.acknowledge(this, meterId)
        ReminderStore.remove(this, meterId)
        result.success(null)
    }

    private fun acknowledge(call: MethodCall, result: MethodChannel.Result) {
        val meterId = meterIdFrom(call)
        if (meterId == null) {
            result.error("missing_meter", "Zähler-ID fehlt.", null)
            return
        }
        ReminderNotifier.acknowledge(this, meterId)
        result.success(null)
    }

    private fun getStatuses(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        val meterIds = (arguments?.get("meterIds") as? List<*>)
            ?.filterIsInstance<String>()
            .orEmpty()
        val activeIds = ReminderNotifier.activeMeterIds(this)
        val statuses = meterIds.map { meterId ->
            mapOf(
                "meterId" to meterId,
                "isNotificationActive" to activeIds.contains(meterId),
                "lastTriggeredAtMillis" to ReminderStore.lastTriggered(this, meterId),
            )
        }
        result.success(statuses)
    }

    private fun meterIdFrom(call: MethodCall): String? {
        val arguments = call.arguments as? Map<*, *>
        return arguments?.get("meterId") as? String
    }

    private fun consumeMeterId(source: Intent?): String? {
        val meterId = source?.getStringExtra("meter_id") ?: return null
        source.removeExtra("meter_id")
        return meterId
    }

    companion object {
        private const val notificationPermissionRequestCode = 4107
    }
}
