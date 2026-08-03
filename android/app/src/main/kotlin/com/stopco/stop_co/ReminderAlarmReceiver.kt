package com.stopco.stop_co

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat

class ReminderAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val CHANNEL_ID = "stop_co_trip_reminder"
        const val EXTRA_TRIP_ID = "tripId"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_NOTIFICATION_ID = "notificationId"
        const val PREFS_NAME = "stop_co_alarm_triggers"
        const val PREFIX = "alarm_triggered_"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val tripId = intent.getStringExtra(EXTRA_TRIP_ID) ?: return
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "Trip Reminder"
        val body = intent.getStringExtra(EXTRA_BODY) ?: ""
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, 2000 + tripId.hashCode())

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val contentIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setAutoCancel(true)
            .setContentIntent(contentIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, notification)

        // Persist trigger so Dart can pick it up even if app is killed
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putLong("$PREFIX$tripId", System.currentTimeMillis()).apply()
    }
}
