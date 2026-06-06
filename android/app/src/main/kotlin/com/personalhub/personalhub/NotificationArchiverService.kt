package com.personalhub.personalhub

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

/**
 * Phase 2B capture engine. The system binds this service while notification
 * access is granted and calls [onNotificationPosted] for every posted
 * notification — including while the Flutter UI is closed. We have no live Dart
 * isolate to deliver to in the background, so each notification is buffered to
 * SharedPreferences; the Dart side drains + uploads it (via the existing sync
 * outbox) the next time the app is opened.
 */
class NotificationArchiverService : NotificationListenerService() {

    // Bounded set of recently captured notification signatures, used to drop the
    // duplicate re-posts Android delivers (e.g. heads-up then collapse-to-bar) so
    // each notification is archived once. In-memory only: rapid re-posts arrive
    // while the service stays bound, and the Dart ingest layer guards restarts.
    private val recentSignatures = object : LinkedHashSet<String>() {
        override fun add(element: String): Boolean {
            val added = super.add(element)
            while (size > MAX_RECENT) remove(iterator().next())
            return added
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val pkg = sbn.packageName ?: return
            if (pkg == applicationContext.packageName) return // skip our own

            // Group summaries duplicate their children's content — archive children only.
            if ((sbn.notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return

            val extras = sbn.notification.extras
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
            val body = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
                ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString()
            if (title.isNullOrBlank() && body.isNullOrBlank()) return // skip empties

            // Same key + same post time = the same notification re-delivered, not a
            // new event (a reused id for a new event bumps postTime). Drop repeats.
            val signature = "${sbn.key}|${sbn.postTime}"
            if (!recentSignatures.add(signature)) return

            val obj = JSONObject().apply {
                put("app_package", pkg)
                put("app_name", resolveAppName(pkg))
                put("title", title)
                put("body", body)
                put("posted_at", sbn.postTime) // epoch millis
                put("key", sbn.key)
            }
            appendPending(obj)
        } catch (e: Exception) {
            // Never let one malformed notification crash the listener.
        }
    }

    private fun resolveAppName(pkg: String): String {
        return try {
            val pm = applicationContext.packageManager
            pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
        } catch (e: Exception) {
            pkg
        }
    }

    private fun appendPending(obj: JSONObject) {
        val prefs =
            applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val arr = JSONArray(prefs.getString(KEY_PENDING, "[]"))
        arr.put(obj)

        // Drop oldest if the app is not opened for a long time (bounded buffer).
        val capped = if (arr.length() > MAX_PENDING) {
            JSONArray().also { out ->
                for (i in (arr.length() - MAX_PENDING) until arr.length()) {
                    out.put(arr.get(i))
                }
            }
        } else {
            arr
        }
        prefs.edit().putString(KEY_PENDING, capped.toString()).apply()
    }

    companion object {
        const val PREFS = "notif_archiver"
        const val KEY_PENDING = "pending_notifications"
        const val MAX_PENDING = 500
        const val MAX_RECENT = 200
    }
}
