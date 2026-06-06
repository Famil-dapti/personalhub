package com.personalhub.personalhub

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isPermissionGranted" -> result.success(isPermissionGranted())
                    "openSettings" -> {
                        openListenerSettings()
                        result.success(null)
                    }
                    "drainPending" -> result.success(drainPending())
                    "getDeviceModel" -> result.success(deviceModel())
                    else -> result.notImplemented()
                }
            }
    }

    // True when our listener is in the system's enabled-notification-listeners list.
    private fun isPermissionGranted(): Boolean {
        val flat = Settings.Secure.getString(
            contentResolver, "enabled_notification_listeners"
        ) ?: return false
        val ours = ComponentName(this, NotificationArchiverService::class.java)
        return flat.split(":").any {
            ComponentName.unflattenFromString(it) == ours
        }
    }

    private fun openListenerSettings() {
        startActivity(
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
    }

    // Returns the buffered notifications as a JSON array string, then clears it.
    private fun drainPending(): String {
        val prefs = getSharedPreferences(
            NotificationArchiverService.PREFS, Context.MODE_PRIVATE
        )
        val data = prefs.getString(NotificationArchiverService.KEY_PENDING, "[]") ?: "[]"
        prefs.edit().remove(NotificationArchiverService.KEY_PENDING).apply()
        return data
    }

    // Human-readable model of this phone, used to attribute captured
    // notifications (the app runs on two phones under one account).
    private fun deviceModel(): String {
        val manufacturer = Build.MANUFACTURER?.replaceFirstChar { it.uppercase() } ?: ""
        val model = Build.MODEL ?: ""
        return "$manufacturer $model".trim().ifEmpty { "Android" }
    }

    companion object {
        private const val CHANNEL = "personalhub/notifications"
    }
}
