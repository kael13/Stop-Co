# Session: Env-ify config, add PhasePlans.md & AGENTS.md to gitignore, rewrite README

## What was done
1. Env-ified the app: extracted hardcoded config/URLs into `.env`, wired with `flutter_dotenv`
   - Created `.env` and `.env.example`
   - Added `flutter_dotenv` dependency
   - Refactored `AppConstants` from `static const` to `static String get` reading from `dotenv.env`
   - Updated `main.dart` to `await dotenv.load()` before Firebase init
   - Replaced hardcoded tile URLs in 3 screens with `AppConstants.tileUrlTemplate`
   - Fixed `const` → `final` on `MethodChannel` in foreground service
   - Moved notification channel constants from `main.dart` into `AppConstants`
2. Added `PhasePlans.md`, `AGENTS.md`, and `android/local.properties` to `.gitignore`
3. Rewrote `README.md` as a concise app introduction

## Key decisions
- `flutter_dotenv` over raw `Platform.environment` — standard Flutter pattern, handles asset bundling
- Every `AppConstants` getter has a hardcoded fallback so app works without `.env`
- `static const` replaced with `static String get` since values are now runtime-dependent
- `PhasePlans.md` and `AGENTS.md` gitignored since they're internal planning / AI instructions

---

# Session: Trip history, nap mode, custom alarm, GPS breadcrumbs, M3 buttons

## Goal
- Implement trip history recording with route persistence, nap mode, custom alarm sound, simulation alignment, GPS breadcrumb travel path, and modernization of the UI components (M3 buttons).

## What was done
1. Trip history data layer: `TripRecord` model, `Trips` Drift table (v1→v2 migration), `TripRepository`, `tripRepositoryProvider`, `recentTripsProvider`
2. Home page: `_RecentTripsSection` + `_TripCard` with tap-to-detail navigation
3. Trip detail screen: `trip_detail_screen.dart` with map showing polyline + stats
4. Nap mode: `napModeEnabled` in `AppSettings`, DB column, Settings toggle, screen dimming via `screen_brightness`, longer vibration pattern in alarm screen
5. Custom alarm sound: `customAlarmSoundPath` in `AppSettings`, DB column, manual path dialog fallback, `recreateAlarmChannel()` in `main.dart`, `UriAndroidNotificationSound` in notification details
6. Simulation alignment: `cancelTrip()` in Stop Simulation button, `_NapModeActiveBanner` on simulation screen
7. GPS breadcrumb recording: `gpsBreadcrumbs` in `ActiveTrip` + `TripRecord`, `addBreadcrumb()` on each position update, green polyline on trip detail map, DB column + v3→v4 migration
8. Simulation pause fix: `WakelockPlus.enable()` during simulation, `_startSimulationPolling()` extracted, `didChangeAppLifecycleState` restarts correct 1s poll timer for simulation
9. Custom alarm sound URI fix: `takePersistableUriPermission()` in `MainActivity.kt`, return `content://` URI directly (no private-storage copy), conditional `file://` prefix in `main.dart` + `alarm_notification_service.dart`
10. AppButton M3 rewrite: replaced `Container` with `FilledButton`/`OutlinedButton`/`FilledButton.tonal`/`TextButton`, kept `GestureDetector` haptic + scale animation, added `isTonal` + `isText` props, 14dp corner radius, 0 elevation, no ripple overlay
11. All changes pass `flutter analyze` with 0 errors (only 4 pre-existing info warnings)
12. Built and ran on device (2311DRK48G wireless) successfully

## Key decisions
- **file_picker replaced with native MethodChannel**: `file_picker` 11.x has Kotlin/AGP 9+ compilation issue — uses `isAgp9OrAbove` check that skips Kotlin plugin, causing `GeneratedPluginRegistrant.java` to fail. Replaced with `startActivityForResult(ACTION_OPEN_DOCUMENT)` in existing `MainActivity.kt`, no new dependencies
- **content:// URIs for alarm sound**: Files copied to private `filesDir/alarms/` produced `file://` URIs inaccessible to Android notification system. Fixed by taking `takePersistableUriPermission()` on the original `content://` URI and passing it directly — survives reboots, no file copy needed
- **Button modernization without shadcn_ui**: User considered `shadcn_ui` (full design system) but chose lighter Option 1+2 — M3 variants inside existing `AppButton` wrapper, keeping custom animation/haptic, zero screen-level refactors
- **Schema migrations**: v1→v2 (Trips table), v2→v3 (napModeEnabled + customAlarmSoundPath), v3→v4 (gpsBreadcrumbsJson). All handled via `MigrationStrategy.onUpgrade`

## Constraints & Preferences
- Prefer minimal dependencies; use built-in Flutter Material 3 where possible (no external UI frameworks)
- Custom alarm sound: avoid `file_picker` package (Kotlin/AGP compatibility issue), use native MethodChannel + `ACTION_OPEN_DOCUMENT` with `content://` URIs
- Nap mode: simple toggle, no auto-detection, no white noise, no snooze
- Button modernization: Option 1+2 — Material 3 variants (`FilledButton`, `OutlinedButton`, `FilledButton.tonal`, `TextButton`) inside existing `AppButton` wrapper with scale animation + haptic kept intact

## Next Steps
- Replace raw `TextButton` usages in `main_shell.dart`, `settings_screen.dart`, `onboarding_screen.dart` with `AppButton(isText: true)`
- Add `screen_brightness`, `wakelock_plus` iOS implementations if targeting iOS
- Consider `flutter_animate` for staggered card loading and active-trip dot pulse (Option A, not yet implemented)

## Critical Context
- **GeneratedPluginRegistrant.java**: Regenerated by Flutter on each build, references all plugins including removed `file_picker`. Must be deleted from `android/app/src/main/java/io/flutter/plugins/` before builds. Not needed for v2 embedding plugins
- **Kotlin version**: Project uses Kotlin 2.3.20 via `settings.gradle.kts`, but `file_picker`'s `isAgp9OrAbove` logic skips Kotlin plugin application. Fixed by removing `file_picker` entirely
- **Deprecation warnings** (pre-existing, not introduced by us): `groupValue` + `onChanged` deprecated in `RadioListTile` at `settings_screen.dart:219-220` (Flutter 3.32+)
- **Build timeout**: `flutter run` timed out at 300s on wireless device — build itself succeeds (`flutter build apk --debug` passes)

## Relevant Files
- `lib/features/trip/data/trip_model.dart` — `ActiveTrip` model with `gpsBreadcrumbs` list
- `lib/features/trip/data/trip_record.dart` — `TripRecord` with JSON serialization for routes + breadcrumbs
- `lib/features/trip/data/trip_providers.dart` — `ActiveTripNotifier` with `addBreadcrumb()`, `_persistTrip()`, `recentTripsProvider`
- `lib/features/trip/data/trip_repository.dart` — `TripRepository` wrapping DB calls
- `lib/features/trip/presentation/trip_detail_screen.dart` — Map with green breadcrumb polyline + grey dotted planned route
- `lib/features/trip/presentation/active_trip_screen.dart` — Screen dimming, wakelock, simulation polling, breadcrumb accumulation
- `lib/features/trip/presentation/alarm_screen.dart` — Brightness restore, nap vibration pattern, custom alarm sound
- `lib/features/settings/data/settings_providers.dart` — `AppSettings` with `napModeEnabled` + `customAlarmSoundPath`
- `lib/features/settings/presentation/settings_screen.dart` — Nap toggle, custom alarm sound tile with native picker + manual fallback
- `lib/features/simulation/presentation/simulation_screen.dart` — Stop Simulation cancels trip, `_NapModeActiveBanner`
- `lib/features/home/presentation/main_shell.dart` — Recent trips section, trip cards with tap-to-detail
- `lib/core/database/database.dart` — 3 tables, schema v4, migration strategy, DAO methods
- `lib/core/components/app_button.dart` — Rewritten with M3 `FilledButton`/`OutlinedButton`/`FilledButton.tonal`/`TextButton`, scale animation + haptic, `isTonal` + `isText` props
- `lib/core/platform/file_picker_channel.dart` — Dart side of native file picker MethodChannel
- `lib/main.dart` — `_initNotifications()` with custom sound URI, `recreateAlarmChannel()`, `_alarmUri()` helper
- `lib/features/trip/data/alarm_notification_service.dart` — `UriAndroidNotificationSound` with conditional `file://` prefix
- `android/app/src/main/kotlin/com/stopco/stop_co/MainActivity.kt` — `ACTION_OPEN_DOCUMENT` file picker, `takePersistableUriPermission()`, returns `content://` URI
- `pubspec.yaml` — Added: `screen_brightness`, `wakelock_plus`. Removed: `file_picker`

---

# Session: Visual overhaul — flutter_animate, shimmer, google_fonts, glassmorphism, Hero transitions

## Goal
- Comprehensive visual overhaul of the Stop-Co Flutter app with an energetic/branded design direction, adding flutter_animate, shimmer, and google_fonts packages, and polishing all screens.

## Constraints & Preferences
- Design direction: "More energetic/branded" — gradients, glassmorphism overlays, bolder color accents on electric blue/teal
- All three new packages approved: flutter_animate ^4.5.2, shimmer ^3.0.0, google_fonts ^6.3.3
- Google Fonts Inter bundled offline (reasonable default chosen)
- Glassmorphism on active trip screen: always-on (reasonable default chosen)
- Auth header: gradient + AppBrand only, no new Lottie
- All screens in scope (user chose "All of the above")

## What was done
1. Phase 1: Foundation — added flutter_animate, shimmer, google_fonts to pubspec.yaml; rewrote `app_typography.dart` to use `GoogleFonts.inter()` (converted all `const TextStyle` to getters, kept fallbacks); updated `app_theme.dart` to remove `const` from TextTheme; created `core/animation/animation_presets.dart` with `fadeSlideUp`, `cardEntrance`, `scaleTapHaptic`, `subtleShimmerSweep`, `buildShimmerBox`, `buildShimmerLine`; deleted orphaned `home_screen.dart`; fixed `alarm_screen.dart` color bug (surface → onSurface); fixed `const` issue in `destination_setup_screen.dart` line 568
2. Phase 3: Auth screen redesign — full rewrite of `auth_screen.dart` with gradient header (primary→secondary), elevated card with rounded top corners, staggered field entrance via flutter_animate, brand header with circular icon, error shake animation
3. Phase 4: Home shell polish — added staggered entrance to `_HomeTabHeader`, `_StartTripSection`, `_DestinationsBlock`, `_RecentTripsBlock`; created `_DestinationsSkeleton` and `_RecentTripsSkeleton` shimmer loaders; added pulsing glow animation to active-trip banner status dot; wrapped distance in `Hero(tag: 'active-trip-distance')`; wrapped trip card icon in `Hero(tag: 'trip-${trip.id}')`; added staggered `fadeSlideUp` to destination cards and trip cards by index; converted `_NavBarItem` to StatefulWidget with scale-down haptic on tap
4. Phase 5: Trip detail screen — full rewrite of `trip_detail_screen.dart` with Hero tag on status icon, 2×2 stat tile grid (`_StatTile` with colored icon chips), animated polyline drawing via `_AnimatedTripMap` with AnimationController (1200ms, easeOutCubic, progressive reveal of traveled+planned routes), destination marker appears at 90% progress
5. Phase 6: Active trip screen — glassy info overlay using `BackdropFilter` blur + 60% surface opacity + colored border; `Hero(tag: 'active-trip-distance')` wired; `AppTypography.distance` style at 48px; pulsing status dot; shimmer sweep on progress bar; replaced user marker with `_PulsingUserMarker` (concentric pulse animation); added `_DestinationPinMarker` with halo ring when within threshold
6. Phase 2: Splash + onboarding — rewrote `_SplashScreen` in `app.dart` with gradient background, animated bell scale-in (easeOutBack), app name + tagline staggered entrance, white spinner; polished `brand_intro_screen.dart` with staggered text entrance + shimmer on "Tap to continue"; polished `onboarding_page.dart` with fadeIn+slideY on title and subtitle
7. Phase 7: Settings + simulation polish — settings screen `_SectionHeader` updated with accent color bar; all sections wrapped with staggered `flutter_animate` reveals; `RadioListTile` for alarm type replaced with `SegmentedButton` with colored icons; simulation screen `_SectionHeader` updated with accent bar; destination selection cards get `AnimatedScale` bounce on selection + staggered fadeIn; simulation status card redesigned with red pulsing "SIMULATION LIVE" badge, `distance` typography for distance readout, speed row with icon
8. Phase 8: Full `flutter analyze` (0 errors, 2 pre-existing info warnings) + `flutter build apk --debug` (succeeded in 49s)

## Key decisions
- `flutter_animate` constrained to ^4.5.2 (4.9.0 doesn't exist)
- AppTypography converted from static `const TextStyle` to getters returning `GoogleFonts.inter()`, with `const` fallbacks preserved for reference
- `app_theme.dart` TextTheme changed from `const TextTheme` to non-const `TextTheme` since GoogleFonts returns runtime values
- SegmentedButton for alarm type replaces deprecated RadioListTile (fixes deprecation warnings at lines 219-220)
- Pulsing user marker created as local `_PulsingUserMarker` in active_trip_screen.dart rather than shared component (scope decision)
- Google Fonts fetched at runtime on first launch unless bundled — chose to accept tiny first-launch penalty (reasonable default)

## Verification
- `flutter analyze`: 0 errors, 2 info warnings (pre-existing `use_build_context_synchronously` in settings_screen.dart lines 576/603 — file-picker manual fallback, unchanged code)
- `flutter build apk --debug`: succeeded — `build/app/outputs/flutter-apk/app-debug.apk`

## Critical Context
- `flutter_animate` `.shake()` uses `offset` as `Offset?` not `int` — fixed with `const Offset(4, 0)`
- `subtleShimmerSweep` is an extension method on `Widget` — works on any widget including `LinearProgressIndicator`
- Pre-existing info warnings in `settings_screen.dart` lines 576/603 (use_build_context_synchronously) — not introduced by this work
- `app_typography.dart` getters cannot be used in `const` contexts — any `const Text(style: AppTypography.xxx)` must be changed to non-const
- Google Fonts fetched at runtime on first launch unless bundled — chose to accept tiny first-launch penalty (reasonable default)

## Fresh install
- Device applicationId: `com.stopco.stop_co`
- Install only: `flutter install`
- Build + run: `flutter run`
- Clean reinstall (uninstall first, then install built APK):
  ```
  adb uninstall com.stopco.stop_co && adb install build/app/outputs/flutter-apk/app-debug.apk
  ```

## Relevant Files
- `pubspec.yaml` — added flutter_animate ^4.5.2, shimmer ^3.0.0, google_fonts ^6.3.3
- `lib/core/theme/app_typography.dart` — rewrote with GoogleFonts.inter() getters + const fallbacks
- `lib/core/theme/app_theme.dart` — removed const from TextTheme for both light and dark
- `lib/core/animation/animation_presets.dart` — NEW: reusable animation presets + shimmer helpers
- `lib/app.dart` — rewrote `_SplashScreen` with gradient + animated bell
- `lib/features/auth/presentation/auth_screen.dart` — full rewrite with gradient header + card + staggered entrance
- `lib/features/home/presentation/main_shell.dart` — skeleton loaders, staggered reveals, Hero tags, pulsing banner, nav micro-interaction
- `lib/features/trip/presentation/trip_detail_screen.dart` — full rewrite with Hero, stat tiles, animated polyline map
- `lib/features/trip/presentation/active_trip_screen.dart` — glassy overlay, pulsing markers, distance typography, shimmer sweep
- `lib/features/onboarding/presentation/brand_intro_screen.dart` — added flutter_animate staggered entrances
- `lib/features/onboarding/presentation/onboarding_page.dart` — added flutter_animate on title/subtitle
- `lib/features/settings/presentation/settings_screen.dart` — accent bars, SegmentedButton, staggered reveals
- `lib/features/simulation/presentation/simulation_screen.dart` — accent headers, recording pulse, distance typography, selection bounce
- `lib/features/destination/presentation/destination_setup_screen.dart` — removed const from Text(style: AppTypography.secondary)
- `lib/features/trip/presentation/alarm_screen.dart` — fixed color bug (surface → onSurface)
