# Privacy Policy

**Last updated:** August 9, 2026

## 1. Introduction

Stop-Co ("the App") is a local-first GPS-based destination alarm for commuters. This Privacy Policy explains how your information is handled when you use the App.

## 2. Data Collection Philosophy

Stop-Co is built on a **local-first** principle. The developer does not operate any backend servers and does not collect, sell, or share your personal data.

However, to provide core functionality (geocoding, map tiles, route calculation), the App communicates with third-party services at your direct request. These communications are described below.

## 3. Local Storage

All data you create within the App is stored exclusively on your device in a local SQLite database:

- Saved destinations and waypoints
- Trip history and GPS breadcrumbs
- App settings (alert radius, alarm preferences, nap mode)
- Saved routes
- Scheduled trips

This data never leaves your device. You can delete all locally stored data at any time via the Settings screen ("Clear Cache" and "Reset Settings") or by uninstalling the App.

## 4. Location Data

Stop-Co uses GPS location solely to determine when you are approaching a destination you have set, and to record your travel path for trip history. Specifically:

- **Foreground and background location** is used only while a trip is actively running, so the alarm can fire even when the App is minimized or the device is locked.
- **Permission is requested explicitly** before any location access begins. You can grant or deny access at any time through your device settings.
- **All location processing happens on-device.** GPS coordinates are never sent to the developer or any analytics service.
- **Trip breadcrumbs** (GPS path of your trip) are stored locally in your trip history and are not uploaded anywhere.

## 5. Third-Party Services

The App communicates with the following third-party services solely to fulfill your direct requests. None of these services receive data other than what is minimally necessary for each request:

| Service | Purpose | Data Sent | Privacy Policy |
|---|---|---|---|
| **Firebase (Google Cloud)** | Geocoding request proxy | Search query text, approximate location | https://firebase.google.com/support/privacy |
| **TomTom** | Geocoding / POI search | Search query text, approximate location | https://tomtom.com/privacy |
| **OSRM** | Route calculation | Start and end coordinates of your trip | https://project-osrm.org |
| **OpenStreetMap (tile servers)** | Map tile rendering | Tile coordinates (z/x/y of viewed map area) | https://osmfoundation.org/privacy |

**How geocoding works:** When you type a location into the search bar, the query is sent through Firebase Cloud Functions, which passes it to TomTom's API. The developer's TomTom API key is stored securely on Firebase's servers and is never exposed to the App. The query itself is not logged or stored by the developer.

The App does **not** share any of the above data with any other party, does not combine it with any other dataset, and does not retain it beyond the immediate request.

## 6. No Analytics or Crash Reporting

The App contains **no analytics SDK, no telemetry, no crash reporter, and no logging framework.** The developer has no visibility into how you use the App or whether it crashes.

## 7. Permissions

The App requests the following Android permissions. Each is used only for the specific purpose listed:

| Permission | Purpose |
|---|---|
| `INTERNET` | Communicate with third-party services (geocoding, map tiles, route calculation) |
| `ACCESS_FINE_LOCATION` | Precise GPS position to determine proximity to your destination |
| `ACCESS_COARSE_LOCATION` | Approximate position when precise GPS is unavailable |
| `ACCESS_BACKGROUND_LOCATION` | Continue monitoring your approach when the App is minimized |
| `POST_NOTIFICATIONS` | Show alarm notifications when you reach your destination |
| `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_LOCATION` | Run location tracking as a foreground service |
| `FOREGROUND_SERVICE_SPECIAL_USE` | Run the scheduled-trip reminder monitor as a foreground service |
| `VIBRATE` | Vibrate device on alarm |
| `WAKE_LOCK` | Keep device CPU awake during active tracking |
| `RECEIVE_BOOT_COMPLETED` | Re-schedule alarms after device reboot |
| `USE_FULL_SCREEN_INTENT` | Show alarm screen full-screen on lock screen |

All permissions are optional. Denying a permission may disable the corresponding feature.

## 8. Children's Privacy

The App is not directed at children under 13. The developer does not knowingly collect any information from children.

## 9. Data Deletion

You can delete data stored by the App at any time:

1. **In the App:** Settings → "Clear Cache" (map tiles) and Settings → "Reset Settings" (restore app preferences to defaults)
2. **System settings:** Clear app data or storage via your device's App Info screen
3. **Uninstall:** Removing the App deletes all locally stored data

## 10. Changes to This Policy

If this Privacy Policy is updated, the "Last updated" date at the top will change. Your continued use of the App after changes constitutes acceptance of the updated policy.

## 11. Contact

For questions about this Privacy Policy, open an issue at:
https://github.com/your-username/stop-co/issues

Or contact the developer at: [your-email@example.com]
