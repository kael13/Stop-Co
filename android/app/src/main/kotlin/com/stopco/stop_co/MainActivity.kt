package com.stopco.stop_co

import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.stopco.app/foreground_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTracking" -> {
                    val latitude = call.argument<Double>("latitude") ?: 0.0
                    val longitude = call.argument<Double>("longitude") ?: 0.0
                    val radius = call.argument<Double>("radius") ?: 300.0
                    val destinationName = call.argument<String>("destinationName") ?: "your stop"
                    val destinationId = call.argument<String>("destinationId") ?: ""

                    val intent = Intent(this, TrackingForegroundService::class.java).apply {
                        putExtra("latitude", latitude)
                        putExtra("longitude", longitude)
                        putExtra("radius", radius)
                        putExtra("destinationName", destinationName)
                        putExtra("destinationId", destinationId)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }

                    result.success(true)
                }
                "stopTracking" -> {
                    val intent = Intent(this, TrackingForegroundService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                "isTracking" -> {
                    result.success(false)
                }
                "updateTrackingNotification" -> {
                    val destinationName = call.argument<String>("destinationName") ?: "your stop"
                    val remainingDistance = call.argument<String>("remainingDistance") ?: ""
                    val intent = Intent(this, TrackingForegroundService::class.java).apply {
                        action = TrackingForegroundService.ACTION_UPDATE
                        putExtra("destinationName", destinationName)
                        putExtra("remainingDistance", remainingDistance)
                    }
                    startService(intent)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
