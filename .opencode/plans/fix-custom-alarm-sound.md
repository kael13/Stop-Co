# Fix: Custom alarm sound — revert to content:// URI with channel-level fix

## Root cause
The custom sound was only applied **per-notification** (via `AndroidNotificationDetails.sound`). On Android 12+, the notification channel's sound is locked at creation time — per-notification overrides are ignored. The sound was also routed through `USAGE_NOTIFICATION` instead of `USAGE_ALARM`, making it subject to DnD suppression.

## The real fix (already applied in Dart files)
- **`main.dart`**: `_createAlarmChannel()` now accepts `customSoundPath`, sets it as the **channel-level** default sound via `AndroidNotificationChannel.sound`, with `audioAttributesUsage: AudioAttributesUsage.alarm` for alarm stream routing. Channel is deleted+recreated with the new sound.
- **`settings_providers.dart`**: Calls `recreateAlarmChannel()` when the user changes the custom sound.
- **`alarm_notification_service.dart`**: Per-notification sound kept as backup; URI logic handles `content://` paths.

## Only change needed: Revert MainActivity.kt
The previous edit replaced `content://` URI return with internal-storage copy. That `file://` approach won't work because the notification system (`system_server` process) can't read app-private `file://` URIs. The original `content://` with `takePersistableUriPermission()` is correct — the notification system CAN access `content://` URIs through the permission grant.

### Exact `MainActivity.kt` content to restore:

```kotlin
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
```

### Dart files — no changes needed (already correct):
- `lib/main.dart` — channel-level sound + `AudioAttributesUsage.alarm` ✓
- `lib/features/settings/data/settings_providers.dart` — calls `recreateAlarmChannel()` ✓
- `lib/features/trip/data/alarm_notification_service.dart` — URI logic handles `content://` ✓
- `lib/features/settings/presentation/settings_screen.dart` — `_displayName` handles `content://` ✓

## Verification
```bash
flutter analyze
flutter build apk --debug
```
