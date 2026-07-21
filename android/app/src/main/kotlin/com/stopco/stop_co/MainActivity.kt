package com.stopco.stop_co

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.PowerManager
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.stopco.app/battery"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestBatteryOptimizationExemption" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                }
                "isIgnoringBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    } else {
                        result.success(true)
                    }
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
                    val internalPath = copyToInternalStorage(uri)
                    val mediaStoreUri = copyToMediaStore(uri)
                    filePickerResult?.success("$internalPath||$mediaStoreUri")
                } catch (e: Exception) {
                    filePickerResult?.success("")
                }
            } else {
                filePickerResult?.success("")
            }
            filePickerResult = null
        }
    }

    private fun copyToMediaStore(uri: android.net.Uri): String {
        val mimeType = contentResolver.getType(uri) ?: "audio/mpeg"
        val extension = detectExtension(uri)

        contentResolver.delete(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            "${MediaStore.Audio.Media.DISPLAY_NAME} = ?",
            arrayOf("stopco_alarm$extension")
        )

        val contentValues = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, "stopco_alarm$extension")
            put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
            put(MediaStore.Audio.Media.TITLE, "StopCo Alarm")
            put(MediaStore.Audio.Media.IS_ALARM, true)
            put(MediaStore.Audio.Media.IS_NOTIFICATION, true)
            put(MediaStore.Audio.Media.IS_MUSIC, false)
            put(MediaStore.Audio.Media.IS_RINGTONE, false)
            put(MediaStore.Audio.Media.RELATIVE_PATH, Environment.DIRECTORY_ALARMS)
        }

        val mediaUri = contentResolver.insert(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            contentValues
        ) ?: throw Exception("Failed to create MediaStore entry")

        contentResolver.openInputStream(uri)?.use { input ->
            contentResolver.openOutputStream(mediaUri)?.use { output ->
                input.copyTo(output)
            } ?: throw Exception("Failed to write to MediaStore")
        } ?: throw Exception("Failed to read source file")

        return mediaUri.toString()
    }

    private fun copyToInternalStorage(uri: android.net.Uri): String {
        val inputStream = contentResolver.openInputStream(uri)
            ?: throw Exception("Cannot open selected file")

        val extension = detectExtension(uri)

        val alarmsDir = File(filesDir, "alarms").also { it.mkdirs() }

        alarmsDir.listFiles()?.forEach { it.delete() }

        val outputFile = File(alarmsDir, "alarm_sound$extension")
        inputStream.use { input ->
            outputFile.outputStream().use { output ->
                input.copyTo(output)
            }
        }
        return outputFile.absolutePath
    }

    private fun detectExtension(uri: android.net.Uri): String {
        val mimeType = contentResolver.getType(uri) ?: ""
        return when {
            mimeType.contains("wav") || mimeType.contains("x-wav") -> ".wav"
            mimeType.contains("mp3") || mimeType.contains("mpeg") -> ".mp3"
            mimeType.contains("ogg") -> ".ogg"
            mimeType.contains("aac") -> ".aac"
            mimeType.contains("flac") -> ".flac"
            mimeType.contains("m4a") -> ".m4a"
            mimeType.contains("webm") -> ".weba"
            else -> {
                val ext = uri.lastPathSegment?.substringAfterLast('.', "")
                if (ext != null && ext.isNotEmpty()) ".$ext" else ".audio"
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
