package com.appfactory.meter_reading_log

import android.Manifest
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private var reminderChannel: MethodChannel? = null
    private var notificationPermissionResult: MethodChannel.Result? = null
    private var pendingBackupSave: PendingBackupSave? = null
    private var statusReceiverRegistered = false
    private val backupIoExecutor = Executors.newSingleThreadExecutor()

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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            backupShareChannelName,
        ).setMethodCallHandler(::handleBackupFileMethod)
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

    override fun onDestroy() {
        backupIoExecutor.shutdown()
        super.onDestroy()
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

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != backupSaveRequestCode) return
        val destination = if (resultCode == Activity.RESULT_OK) data?.data else null
        completeBackupSave(destination)
    }

    private fun handleReminderMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "areNotificationsEnabled" ->
                result.success(ReminderNotifier.notificationsEnabled(this))
            "requestNotificationPermission" -> requestNotificationPermission(result)
            "canScheduleExactAlarms" ->
                result.success(ReminderScheduler.canScheduleExact(this))
            "requestExactAlarmPermission" -> requestExactAlarmPermission(result)
            "openExactAlarmSettings" -> result.success(openExactAlarmSettings())
            "schedule" -> schedule(call, result)
            "cancel" -> cancel(call, result)
            "acknowledge" -> acknowledge(call, result)
            "getStatuses" -> getStatuses(call, result)
            "showReminderTest" -> showReminderTest(call, result)
            "consumeInitialMeterId" -> result.success(consumeMeterId(intent))
            else -> result.notImplemented()
        }
    }

    private fun handleBackupFileMethod(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "saveBackup" -> saveBackup(call, result)
            "shareBackup" -> shareBackup(call, result)
            else -> result.notImplemented()
        }
    }

    private fun saveBackup(call: MethodCall, result: MethodChannel.Result) {
        if (pendingBackupSave != null) {
            result.error("save_pending", "Eine Speicherortwahl läuft bereits.", null)
            return
        }
        val arguments = call.arguments as? Map<*, *>
        val path = arguments?.get("path") as? String
        if (path.isNullOrBlank()) {
            result.error("missing_path", "Der Backup-Pfad fehlt.", null)
            return
        }
        try {
            val backup = validatedBackup(path)
            pendingBackupSave = PendingBackupSave(backup, result)
            @Suppress("DEPRECATION")
            startActivityForResult(
                Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/octet-stream"
                    putExtra(Intent.EXTRA_TITLE, backup.name)
                },
                backupSaveRequestCode,
            )
        } catch (error: Exception) {
            pendingBackupSave = null
            result.error("save_failed", error.message, null)
        }
    }

    private fun completeBackupSave(destination: Uri?) {
        val request = pendingBackupSave ?: return
        if (destination == null) {
            pendingBackupSave = null
            request.result.success(mapOf("status" to "cancelled"))
            return
        }
        backupIoExecutor.execute {
            try {
                request.backup.inputStream().buffered(backupCopyBufferSize).use { input ->
                    val output = contentResolver.openOutputStream(destination, "w")
                        ?: throw IllegalStateException("Der Speicherort konnte nicht geöffnet werden.")
                    output.buffered(backupCopyBufferSize).use { target ->
                        input.copyTo(target, backupCopyBufferSize)
                    }
                }
                val fileName = destinationDisplayName(destination) ?: request.backup.name
                runOnUiThread {
                    pendingBackupSave = null
                    request.result.success(
                        mapOf("status" to "saved", "fileName" to fileName),
                    )
                }
            } catch (error: Exception) {
                deleteIncompleteDestination(destination)
                runOnUiThread {
                    pendingBackupSave = null
                    request.result.error("save_failed", error.message, null)
                }
            }
        }
    }

    private fun shareBackup(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        val path = arguments?.get("path") as? String
        val title = arguments?.get("title") as? String ?: "ZählerstandLog Backup"
        val text = arguments?.get("text") as? String
        if (path.isNullOrBlank()) {
            result.error("missing_path", "Der Backup-Pfad fehlt.", null)
            return
        }
        try {
            val backup = validatedBackup(path)
            clearLegacyShareCache()
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.backup_provider",
                backup,
            )
            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = "application/octet-stream"
                putExtra(Intent.EXTRA_STREAM, uri)
                if (!text.isNullOrBlank()) putExtra(Intent.EXTRA_TEXT, text)
                clipData = ClipData.newRawUri(backup.name, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            packageManager.queryIntentActivities(
                shareIntent,
                PackageManager.MATCH_DEFAULT_ONLY,
            ).forEach { target ->
                grantUriPermission(
                    target.activityInfo.packageName,
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
            }
            startActivity(Intent.createChooser(shareIntent, title))
            result.success(null)
        } catch (error: Exception) {
            result.error("share_failed", error.message, null)
        }
    }

    private fun validatedBackup(path: String): File {
        val backupRoot = File(cacheDir, "meter_reading_backups").canonicalFile
        val backup = File(path).canonicalFile
        val isInsideBackupRoot = backup.path.startsWith(
            backupRoot.path + File.separator,
        )
        if (!isInsideBackupRoot || !backup.isFile) {
            throw IllegalArgumentException("Die Backup-Datei ist ungültig.")
        }
        return backup
    }

    private fun destinationDisplayName(destination: Uri): String? = try {
        contentResolver.query(
            destination,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) cursor.getString(index) else null
        }
    } catch (_: Exception) {
        null
    }

    private fun deleteIncompleteDestination(destination: Uri) {
        try {
            DocumentsContract.deleteDocument(contentResolver, destination)
        } catch (_: Exception) {
            // Some document providers do not allow deleting a failed target.
        }
    }

    private fun clearLegacyShareCache() {
        File(cacheDir, "share_plus").listFiles()?.forEach { file ->
            file.deleteRecursively()
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
        result.success(openExactAlarmSettings())
    }

    private fun openExactAlarmSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        return try {
            startActivity(
                Intent(
                    Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                    Uri.parse("package:$packageName"),
                ),
            )
            true
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM))
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun schedule(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        val meterId = arguments?.get("meterId") as? String
        val label = arguments?.get("label") as? String
        val meterType = arguments?.get("meterType") as? String
        val meterTypeLabel = arguments?.get("meterTypeLabel") as? String
        val interval = arguments?.get("interval") as? String
        val day = arguments?.get("day") as? Int
        val hour = arguments?.get("hour") as? Int
        val minute = arguments?.get("minute") as? Int
        val deliveryMode = arguments?.get("deliveryMode") as? String
        if (
            meterId.isNullOrBlank() || label.isNullOrBlank() ||
            meterType.isNullOrBlank() || meterTypeLabel.isNullOrBlank() ||
            interval.isNullOrBlank() ||
            day == null || hour == null ||
            minute == null || deliveryMode.isNullOrBlank()
        ) {
            result.error("invalid_schedule", "Erinnerungsdaten sind unvollständig.", null)
            return
        }
        val reminder = StoredReminder(
            meterId = meterId,
            label = label,
            meterType = meterType,
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

    private fun showReminderTest(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        val label = arguments?.get("label") as? String
        val meterType = arguments?.get("meterType") as? String
        val meterTypeLabel = arguments?.get("meterTypeLabel") as? String
        val deliveryMode = arguments?.get("deliveryMode") as? String
        if (
            label.isNullOrBlank() || meterType.isNullOrBlank() ||
            meterTypeLabel.isNullOrBlank() || deliveryMode.isNullOrBlank()
        ) {
            result.error("invalid_test", "Testdaten sind unvollständig.", null)
            return
        }
        result.success(
            ReminderNotifier.showTest(
                context = this,
                meterId = arguments["meterId"] as? String,
                label = label,
                meterType = meterType,
                meterTypeLabel = meterTypeLabel,
                latestValue = arguments["latestValue"] as? String,
                latestUnit = arguments["latestUnit"] as? String,
                punctual = deliveryMode == "punctualWithSound",
            ),
        )
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
        private const val backupCopyBufferSize = 256 * 1024
        private const val backupSaveRequestCode = 4108
        private const val notificationPermissionRequestCode = 4107
        private const val backupShareChannelName =
            "com.appfactory.meter_reading_log/backup_share"
    }

    private data class PendingBackupSave(
        val backup: File,
        val result: MethodChannel.Result,
    )
}
