package com.stopco.stop_co

import android.app.*
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class TrackingForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "stop_co_tracking"
        const val NOTIFICATION_ID = 1001
        const val ACTION_STOP = "com.stopco.stop_co.STOP_TRACKING"
        const val ACTION_UPDATE = "com.stopco.stop_co.UPDATE_TRACKING"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_UPDATE -> {
                val name = intent.getStringExtra("destinationName") ?: "your stop"
                val distance = intent.getStringExtra("remainingDistance") ?: ""
                val notification = buildNotification(name, distance)
                startForeground(NOTIFICATION_ID, notification)
                return START_STICKY
            }
            else -> {
                val destinationName = intent?.getStringExtra("destinationName") ?: "your stop"
                val notification = buildNotification(destinationName, "")
                startForeground(NOTIFICATION_ID, notification)
                return START_STICKY
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Stop-Co Tracking",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Shows when Stop-Co is actively tracking your destination"
            setShowBadge(false)
        }

        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(
        destinationName: String,
        remainingDistance: String
    ): Notification {
        val stopIntent = Intent(this, TrackingForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val launchPendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val contentText = if (remainingDistance.isNotEmpty()) {
            "Destination: $destinationName • Remaining: $remainingDistance"
        } else {
            "Tracking to $destinationName"
        }

        val bigText = if (remainingDistance.isNotEmpty()) {
            "Remaining: $remainingDistance\nDestination: $destinationName"
        } else {
            "Tracking to $destinationName"
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Active trip")
            .setContentText(contentText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(bigText))
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setOngoing(true)
            .setContentIntent(launchPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPendingIntent)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }
}
