package com.stopco.stop_co

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.stopco.app/foreground_service"
    private val FILE_PICKER_CHANNEL = "com.stopco.app/file_picker"

    private var filePickerResult: MethodChannel.Result? = null
    private val FILE_PICKER_REQUEST_CODE = 1001

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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FILE_PICKER_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickAudioFile" -> {
                    filePickerResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "audio/*"
                    }
                    startActivityForResult(intent, FILE_PICKER_REQUEST_CODE)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == FILE_PICKER_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val uri = data.data!!
                try {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                    filePickerResult?.success(uri.toString())
                } catch (e: Exception) {
                    filePickerResult?.success("")
                }
            } else {
                filePickerResult?.success("")
            }
            filePickerResult = null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
