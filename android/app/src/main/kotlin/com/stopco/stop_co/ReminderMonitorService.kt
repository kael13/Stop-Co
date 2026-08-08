package com.stopco.stop_co

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject

class ReminderMonitorService : Service() {

    companion object {
        const val CHANNEL_ID = "stop_co_reminder_monitor"
        const val ALARM_CHANNEL_ID = "stop_co_scheduled_alarm"
        const val NOTIFICATION_ID = 3001
        const val EXTRA_REMINDERS = "reminders"
        const val PREFS_NAME = "stop_co_alarm_triggers"
        const val PREFS_PREFIX = "alarm_triggered_"
        const val ACTION_STOP = "com.stopco.stop_co.STOP_REMINDER_MONITOR"
        private const val CHECK_INTERVAL_MS = 30_000L
    }

    private val handler = Handler(Looper.getMainLooper())
    private val checkRunnable = Runnable { checkAndNotify() }
    private val reminders = mutableListOf<ReminderEntry>()

    data class ReminderEntry(
        val tripId: String,
        val title: String,
        val body: String,
        val triggerTimeMs: Long,
        var notified: Boolean = false
    )

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        val remindersJson = intent?.getStringExtra(EXTRA_REMINDERS) ?: ""
        if (remindersJson.isNotEmpty()) {
            reminders.clear()
            try {
                val arr = JSONArray(remindersJson)
                for (i in 0 until arr.length()) {
                    val obj = arr.getJSONObject(i)
                    reminders.add(ReminderEntry(
                        tripId = obj.getString("tripId"),
                        title = obj.getString("title"),
                        body = obj.getString("body"),
                        triggerTimeMs = obj.getLong("triggerTimeMs")
                    ))
                }
            } catch (_: Exception) {}
        }

        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
        handler.post(checkRunnable)
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacks(checkRunnable)
        super.onDestroy()
    }

    private fun checkAndNotify() {
        val now = System.currentTimeMillis()
        var allDone = true

        for (reminder in reminders) {
            if (reminder.notified) continue
            if (isTriggerPersisted(reminder.tripId)) {
                reminder.notified = true
                continue
            }
            allDone = false

            if (now >= reminder.triggerTimeMs) {
                showNotification(reminder)
                persistTrigger(reminder.tripId, now)
                reminder.notified = true
            }
        }

        if (allDone) {
            stopSelf()
        } else {
            handler.postDelayed(checkRunnable, CHECK_INTERVAL_MS)
        }
    }

    private fun isTriggerPersisted(tripId: String): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.contains("$PREFS_PREFIX$tripId")
    }

    private fun showNotification(reminder: ReminderEntry) {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            putExtra("scheduledTripId", reminder.tripId)
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            this, reminder.tripId.hashCode(), launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, ALARM_CHANNEL_ID)
            .setContentTitle(reminder.title)
            .setContentText(reminder.body)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setDefaults(NotificationCompat.DEFAULT_SOUND or NotificationCompat.DEFAULT_VIBRATE)
            .build()

        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(reminder.tripId.hashCode() + 5000, notification)
    }

    private fun persistTrigger(tripId: String, nowMs: Long) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putLong("$PREFS_PREFIX$tripId", nowMs).apply()
    }

    private fun buildNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Reminder monitor")
            .setContentText("Monitoring scheduled trip reminders")
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val monitorChannel = NotificationChannel(
                CHANNEL_ID,
                "Scheduled Reminders",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors scheduled trip reminders"
                setShowBadge(false)
            }
            nm.createNotificationChannel(monitorChannel)

            val alarmChannel = NotificationChannel(
                ALARM_CHANNEL_ID,
                "Scheduled Trip Alarms",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts for scheduled trip departures"
                enableVibration(true)
                setShowBadge(true)
            }
            nm.createNotificationChannel(alarmChannel)
        }
    }
}
