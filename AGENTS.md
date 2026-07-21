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

---

# Session: Community tab — Reddit-style posts, votes, comments, guest gate, images, coordinates

## Goal
Add a "Community" tab with Reddit-style posts (create/update/delete), upvote+downvote, flat comments, 3 images per post, coordinates with map preview, sort by relevant/topvoted/recent, and guest read-only with email-verified-only writes.

## Constraints & Preferences
- Auth: Firebase Auth (email, Google, anonymous), with Google Sign-In broken without SHA-1.
- Database: Firebase Firestore + Storage (chose Firestore over Supabase/custom API).
- Guest: unauthenticated users read-only; anonymous Firebase users also blocked from write.
- Email verification required to post/vote/comment (Google users auto-verified).
- 15-minute edit lock on posts and comments.
- Up to 3 images per post, 1 per comment; images stored in Firebase Storage (no blobs in DB).
- Coordinates optional; when set, displayed as tappable chip → MapPreviewScreen (OSM).
- Post-moderation (approved by default; flagged auto-hidden; dashboard future).
- Existing app: Riverpod (manual, no codegen), Drift SQLite for destinations/trips, Flutter Map for maps, `file_picker` banned (AGP issue) — using `image_picker` instead.
- No new backend API — Flutter talks to Firebase directly.
- Comment images deferred to future phase (text-only in current implementation).

## What was done
### Phase A.0 — Foundation
- Added deps: `cloud_firestore`, `firebase_storage`, `image_picker` to pubspec.yaml.
- Extended `UserSignedIn` with `photoURL` field.
- Created `lib/features/community/` with domain enums (`CommunitySort`, `ModerationStatus`, `VoteValue`), models (`CommunityPost`, `CommunityComment`), `CommunityRepository` (all CRUD + vote transactions + Storage helpers), and `community_providers.dart` (manual Riverpod).

### Phase A.0.1 — Auth foundations
- Added `sendEmailVerification()` to `registerWithEmail`.
- Added `reloadCurrentUser()` and `resendEmailVerification()` to AuthRepository.
- Added `emailVerified` field to `UserSignedIn` with `canWriteCommunity` getter.
- Created `auth_action_providers.dart` with reload and resend action providers.
- Updated AuthScreen: post-registration snackbar, persistent verification banner with `[Resend]` and `[I've verified]` buttons, auto-hides on verify.
- Created `guest_gate_dialog.dart` — Option B dialog ("Maybe later" / "Sign in") for anonymous/unverified write attempts.

### Phase A.1 — Feed UI
- Added Community as 5th tab in `main_shell.dart` (groups_2 icon, between Simulate and Settings).
- Created `CommunityFeedTab` with sort chips (`SegmentedButton<CommunitySort>`: relevant/topVoted/recent), shimmer skeleton loader, empty state, pull-to-refresh, and FAB (`"New Post"` for writers, `"Sign in to Post"` for guests → gate dialog).
- Created `PostCard` with author row, description, 3-image grid, tappable coordinate chip, vote/comment footer, staggered fadeSlideUp animation.
- Created `CoordinateChip` → `MapPreviewScreen` (FlutterMap + OSM tiles + "Open in Google Maps" via url_launcher).

### Phase A.2 — Post creation
- Created `PostComposerScreen` with description field (500 char limit), 3-slot image picker (Android Photo Picker, `content://` URIs), map-tap coordinate picker, "Use my location" button, auto reverse-geocoding (Nominatim), submit with image upload → Firestore create.
- Made coordinates optional (only description required).

### Phase A.3 — Engagement
- Added new providers to `community_providers.dart`: `watchCommentsProvider`, `voteCommentActionProvider`, `addCommentActionProvider`, `updateCommentActionProvider`, `deleteCommentActionProvider`, `updatePostActionProvider`, `deletePostActionProvider`, `myPostVotesProvider`, `myCommentVotesProvider`.
- Created `PostDetailScreen` with live post header (`communityPostProvider`), interactive vote bar (highlighted via `myPostVotesProvider`), comments list from `watchCommentsProvider` (sorted by score-then-recent), per-comment vote arrows + edit/delete (author-only, 15-min lock), comment composer (text field + send button), guest gate on all write surfaces, post overflow menu (Edit description dialog / Delete with confirm).
- Updated `PostCard` footer arrows to be tappable with `myVote` highlight and `onVote` callback; guest gate on vote tap.
- Wired `CommunityFeedTab` to push `PostDetailScreen` on PostCard tap, watch `myPostVotesProvider` for visible post highlights, invalidate my-votes after each vote.

### Image upload fix
- Switched `uploadPostImage` / `uploadCommentImage` from `putData(bytes)` → temp file + `putFile` (more reliable on Android for `content://` URIs).
- Added proper `contentType` metadata (`image/jpeg`, `image/png`, `image/webp`).
- Added empty bytes guard.
- Added retry logic (up to 3 attempts with backoff) for `getDownloadURL` against transient `object-not-found`.
- Made image uploads per-image resilient: one failed image skips it but doesn't abort the whole post; SnackBar warns about failures.

### Firebase console tasks
- Added debug SHA-1 `D5:08:2B:9D:54:04:98:1C:E2:AA:48:72:00:D1:A3:18:61:AE:76:27` → downloaded new `google-services.json` (oauth_client now populated, fixing Google Sign-In API10 error).
- Firestore rules with `isVerifiedWriter()` (email_verified gate) and `sign_in_provider` fallback for anonymous block.
- Storage rules matching email_verified gate.
- 5 composite indexes created (posts: moderationStatus+createdAt, moderationStatus+score+createdAt, moderationStatus+hot; comments: postId+score+createdAt, postId+createdAt).
- 1 additional composite index for comments: `postId` (asc) / `moderationStatus` (asc) / `score` (desc) / `createdAt` (desc) — user created via Console.

## Key decisions
- Firestore + Storage over Supabase/custom API (chosen over original Postgres plan).
- Post-moderation (visible immediately, flagged posts auto-hidden; moderation dashboard deferred).
- Flat comments (no nesting) for lightweight UI.
- Coordinates optional (user asked "is this required?" — only description required).
- 3 images per post, 1 per comment.
- "Option I" for deep-linking: manual `[Refresh]` button, no auto-return from email verification.
- Guest = unauthenticated (anonymous Firebase users also blocked from write — `sign_in_provider` check).
- Email verification required (both Firestore rules and client gate).
- Comment images deferred (text-only for A.3 — repo supports it but UI excluded).
- Report post deferred to A.4 Moderation phase.
- Vote in both feed cards and detail screen (chosen over detail-only).
- Edit + Delete post in A.3 (chosen over deferring to A.4).
- One-shot `FutureProvider` for my-votes state (chosen over live `StreamProvider`).

## Verification
- `flutter analyze`: 0 errors, 2 pre-existing info warnings (`settings_screen.dart:576,603`).
- `flutter build apk --debug`: succeeds (~20-80s depending on plugin regeneration).

## Critical Context
- Google Sign-In was broken (`api10` / `DEVELOPER_ERROR`) because `google-services.json` had empty `"oauth_client": []` — fixed by adding SHA-1 fingerprint `D5:08:2B:9D:54:04:98:1C:E2:AA:48:72:00:D1:A3:18:61:AE:76:27` in Firebase console and re-downloading the file.
- `image_picker` on Android 13+ returns `content://` URIs in `XFile.path` — upload must read bytes via `XFile.readAsBytes()` then write to a temp file for `putFile()` with proper `contentType` metadata; `putData(bytes)` had a race condition with `getDownloadURL()`.
- Need to add release SHA-1 from Play Console if publishing.
- No deep-link auto-return from email verification — user must tap `[I've verified]` button.
- The `canWriteCommunity` gate expression: `!isAnonymous && emailVerified`.
- `watchComments` requires a 4-field composite index in Firebase Console — user created it (postId asc / moderationStatus asc / score desc / createdAt desc).
- `comments` query: `where('postId', ==) + where('moderationStatus', ==) + orderBy('score', desc) + orderBy('createdAt', desc)` — needs matching index (now created and Enabled).

## Next Steps
- Phase A.4 — Moderation: report button, flagged-self-view blur, SafeSearch Cloud Function (deferred).
- Phase B (future) — Moderation dashboard (web admin).
- "My Posts" screen, profile/user page, push notifications for replies — deferred.
- Polish / bug fixes on A.3 as needed.

## Relevant Files
- `lib/features/community/presentation/community_feed_tab.dart`: 5th tab — feed, sort chips, FAB, shimmer skeleton, wired to push PostDetailScreen, watches `myPostVotesProvider`.
- `lib/features/community/presentation/post_composer_screen.dart`: create post form with image picker, map-tap coords, submit.
- `lib/features/community/presentation/post_card.dart`: feed card — author, images, coord chip, interactive vote arrows with highlight, guest gate.
- `lib/features/community/presentation/post_detail_screen.dart`: full-screen post view with live header, vote bar, comments list, comment composer, edit/delete overflow.
- `lib/features/community/presentation/coordinate_chip.dart`: tappable chip → MapPreviewScreen.
- `lib/features/community/presentation/map_preview_screen.dart`: OSM full-screen map.
- `lib/features/community/presentation/guest_gate_dialog.dart`: option-B dialog for unverified/anonymous users.
- `lib/features/community/data/community_repository.dart`: Firestore + Storage CRUD, vote transactions, image upload via temp file + `putFile`.
- `lib/features/community/data/community_providers.dart`: Riverpod providers (feed, post, votes, comments, CRUD actions, my-votes).
- `lib/features/community/data/models/`: `community_post.dart`, `community_comment.dart`.
- `lib/features/community/domain/`: `community_sort.dart`, `moderation_status.dart`, `vote_value.dart`.
- `lib/features/auth/data/auth_repository.dart`: `registerWithEmail` → sends verification email, `reloadCurrentUser`, `resendEmailVerification`.
- `lib/features/auth/data/auth_providers.dart`: `UserSignedIn` with `emailVerified` + `canWriteCommunity`.
- `lib/features/auth/data/auth_action_providers.dart`: reload + resend action providers.
- `lib/features/auth/presentation/auth_screen.dart`: verification banner with `[Resend]` + `[I've verified]`, post-registration snackbar.
- `lib/features/home/presentation/main_shell.dart`: 5-tab nav (Home, Saved, Simulate, Community, Settings).
- `android/app/google-services.json`: updated with non-empty `oauth_client` (Google Sign-In fix).
- `pubspec.yaml`: added `cloud_firestore`, `firebase_storage`, `image_picker`.

---

# Session: Multi-waypoint alarm pins — single-stop panel UX fix

## Goal
- Implement multi-waypoint alarm pins on the map while keeping single-destination flow identical to original. Additional waypoints optional; single destination UI must remain identical when only one pin is placed.

## Constraints & Preferences
- Additional waypoints must be optional; single destination UI must remain identical when only one pin is placed.
- Sequential waypoints (A→B→C) that trigger alarms on arrival; trip auto-completes after last stop.
- Per-pin alert radius; waypoints set before trip only; waypoints persisted in history.
- Numbered markers (1, 2, 3) on map; current waypoint pulses, past ones show checkmark.
- Celebration screen on trip completion; saved Destinations available as quick-add chips on planner.
- Single-stop bottom panel must show old UI (name input + radius chips + Start Trip + Save Only) — not the multi-stop list.
- User enters multi-stop mode explicitly via "Add another stop" link.

## What was done
- `Waypoint` model (`lib/features/trip/data/waypoint.dart`) with JSON serialization.
- `ActiveTrip` model: `List<Waypoint>` replaces single `Destination`; `currentWaypoint` getter, `hasMultipleStops`, `totalStops`.
- `TripRecord`: `waypointsJson` column, schema v4→v5 migration.
- `ActiveTripNotifier`: `startTrip(Destination)` backward compat, `startTripWithWaypoints(List<Waypoint>)`, `advanceToNextWaypoint()`, `clearTrip()`.
- `GeofenceManager`: checks `currentWaypoint` instead of destination.
- `DestinationSetupScreen`: full rewrite as waypoint planner with single-stop and multi-stop modes.
- `ActiveTripScreen`: numbered waypoint markers, stop progress overlay.
- `AlarmScreen`: stop advancement logic (dismiss → next stop or complete).
- `TripCompleteScreen`: celebration screen with stops list and mini route map.
- `TripDetailScreen`: numbered waypoint markers on history map, stops section.
- `SimulationService`: decoupled from `Destination` model (takes lat/lng/name).
- `MainShell`: trip card shows stop count badge when `waypoints.length > 1`.
- All route registration (`app.dart`).

### Fix: single-stop panel UX
- Added `_multiMode` flag (default `false`) to `DestinationSetupScreen`.
- `_onMapTap` / `_selectSearchResult`: when `!_multiMode` and a waypoint exists, **replaces** the single waypoint (old "move pin" behavior). Only **appends** when in multi-mode.
- `_buildPlannerBottomSheet` dispatches:
  - 0 waypoints → empty state
  - 1 waypoint + `!_multiMode` → `_buildSingleStopPanel()` (old UI)
  - ≥2 waypoints or `_multiMode` → multi-stop list
- Added `_buildSingleStopPanel()` with exact old UI: name `AppInput`, radius `ChoiceChip`s, "Start Trip" + "Save Only" buttons, "Add another stop" link.
- Added `_enterMultiMode()` to set flag and pan to user location.
- `flutter analyze`: 0 errors, 0 warnings, 5 info.

## Key decisions
- `_multiMode` stays `true` for the session once user taps "Add another stop".
- `startTrip(Destination)` kept as backward compat wrapper creating single-element Waypoint list.
- `SimulationService` changed from `Destination` parameter to individual lat/lng/name params.
- `completeTrip()` no longer nulls ActiveTrip state; `TripCompleteScreen` reads from provider and calls `clearTrip()` on exit.

## Verification
- `flutter analyze`: 0 errors, 0 warnings (5 info — 2 `prefer_is_empty`, 2 pre-existing `use_build_context_synchronously`, 1 `unnecessary_underscores`).
- `flutter build apk --debug`: succeeded.

## Critical Context
- `_multiMode` default false. Once user taps "Add another stop", stays true for session.
- `_onMapTap` currently always appends; must check `!_multiMode && _waypoints.length >= 1` to replace instead.
- `AppInput` accepts `suffix` (Widget) not `suffixIcon`.
- `AppCard` has no `margin` property; use Padding wrapper.
- `MapOptions.onTap` signature is `void Function(TapPosition, LatLng)`.
- `ReorderableListView.onReorder` is deprecated; use `onReorderItem`.
- `SimulationService.start()` no longer accepts `Destination`.

## Next Steps
- None (fix complete).

## Relevant Files
- `lib/features/destination/presentation/destination_setup_screen.dart` — single-stop panel UX fix (`_multiMode`, `_buildSingleStopPanel`, dispatch logic).
- `lib/features/trip/data/waypoint.dart` — Waypoint model.
- `lib/features/trip/data/trip_model.dart` — ActiveTrip with waypoints list + currentWaypoint getter.
- `lib/features/trip/data/trip_providers.dart` — Multi-waypoint engine.
- `lib/features/trip/data/geofence_manager.dart` — Uses currentWaypoint.
- `lib/features/trip/presentation/active_trip_screen.dart` — Numbered markers, stop progress overlay.
- `lib/features/trip/presentation/alarm_screen.dart` — Stop advancement logic.
- `lib/features/trip/presentation/trip_complete_screen.dart` — Celebration screen.
- `lib/features/trip/presentation/trip_detail_screen.dart` — Waypoints in history.
- `lib/features/simulation/data/simulation_service.dart` — Decoupled from Destination.
- `lib/core/database/database.dart` — Schema v5 with waypointsJson column.
- `lib/app.dart` — Route registration for /trip-complete.

---

# Session: Multi-waypoint alarm pins — UX compaction & bug fixes

## Goal
- Limit alarm pins to 5 max, fix persistent action buttons in multi-stop mode, compact/modern font (Google Fonts Inter), fix simulation alarm re-triggering loop and immediate re-trigger on stop advance.

## Constraints & Preferences
- Max 5 stops per trip.
- "Save Only" and "Start Trip" buttons always visible in multi-stop mode.
- Compact modern UI using `AppTypography` (Inter).
- Alarm must only fire when user has truly left the previous stop's alert zone and arrived at the current stop.
- Simulation must advance through all stops without looping.

## What was done
- `AppConstants.maxWaypoints`: 10 → 5; max-limit SnackBar guards in `_onMapTap()` / `_selectSearchResult()`.
- `_buildWaypointList()` bottom row: unconditional button row (removed `if (length == 1)` guard).
- `_WaypointRow` compact: 24px circle, 11px number, `AppTypography.secondary` (14px) name, `caption` for radius, 28px icon buttons, 2px vertical padding.
- `_buildPlannerBottomSheet` `maxHeight`: 0.45 → 0.40.
- All sheet sections: padding and spacings reduced (sm→xs, xs→xxs, md→sm).
- Sheet titles: `AppTypography.title` (24px) → `AppTypography.sectionHeader` (18px).
- Empty planner: icon 40→28, fonts switched to `secondary`/`caption`.
- `_buildSingleStopPanel`: "Where are you heading?" → "Where to?"; spacing tightened.
- `_buildEditBottomSheet`: spacing tightened, title "Edit Destination" → "Edit".
- FAB bottom position: 280 → 260.
- All raw `Theme.of(context).textTheme.*` replaced with `AppTypography.*`.
- Search results: raw `bodySmall` → `AppTypography.secondary`.
- `ChoiceChip`s: added `visualDensity: VisualDensity.compact`.
- Simulation screen: multi-waypoint selection UI with numbered chips, remove button, up to 5 stops, calls `startTripWithWaypoints()`.
- `hasLeftPrevZone` alarm gate in `active_trip_screen.dart`: alarm fires only when distance to previous stop > its alert radius AND ≤ current stop's radius.
- `alarm_screen.dart` `_dismiss()`: immediately repoints simulation to next waypoint (not last stop), stops simulation only on last stop.
- `trip_complete_screen.dart`: `clearTrip()` on exit, `mounted` guard.

## Key decisions
- `hasLeftPrevZone` over time-cooldown or `_wasOutsideRadius`: handles close stops and both simulation/real GPS correctly.
- Simulation repointing in `_dismiss()`: immediate set next waypoint so simulation heads in the right direction while route is being fetched.
- Option A for simulation tab: picks up planner waypoints via multi-select from saved destinations, converts to `Waypoint`s, calls `startTripWithWaypoints()`.
- Compact font strategy: `AppTypography.secondary` (14px Inter) for form content, `sectionHeader` (18px) for titles, `caption` (12px) for secondary info.

## Verification
- `flutter analyze`: 0 errors, 0 warnings (3 pre-existing info — `unnecessary_underscores` in destination_setup_screen, `use_build_context_synchronously` in settings_screen).
- `flutter build apk --debug`: succeeded.

## Critical Context
- Bug "stop 2 triggers immediately after dismiss" caused by simulation still heading to old stop + distance already ≤ new stop alert radius. Fixed by `hasLeftPrevZone`.
- Bug "loops on last stop" caused by completed trip state not being cleared + stale callbacks. Fixed by `clearTrip()` on exit + immediate simulation repointing + `hasLeftPrevZone`.
- `isLastStop` check in `_dismiss()`: simulation stopped + disabled on last stop only.
- `_multiMode` default false; once set, stays true for session.

## Next Steps
- (none — compaction and bug fixes complete)
- Verify multi-waypoint flow in simulation mode: create 2-3 close stops → start simulation → dismiss each alarm sequentially → trip completes without loops.

## Relevant Files
- `lib/core/constants/app_constants.dart` — maxWaypoints 10→5.
- `lib/features/destination/presentation/destination_setup_screen.dart` — max guards, persistent buttons, compact layout, modern fonts, progress bar, reduced spacing, maxHeight 0.40, VisualDensity.compact.
- `lib/features/trip/presentation/alarm_screen.dart` — simulation repointing on advance, stop on last stop only.
- `lib/features/trip/presentation/active_trip_screen.dart` — hasLeftPrevZone alarm gate.
- `lib/features/trip/presentation/trip_complete_screen.dart` — clearTrip() on exit, mounted guard.
- `lib/features/simulation/presentation/simulation_screen.dart` — multi-waypoint selection UI, startTripWithWaypoints().

---

# Session: Lock-screen alarm & lifecycle fix — no loop, no screen wake on repeat, CPU alive

## Goal
- Fix trip completion loop on lock screen (alarm kept re-triggering until app unlocked/reopened)
- Minimize app to notification bar on lock (no activity overlay when no alarm is active)
- Keep CPU alive during tracking (PARTIAL_WAKE_LOCK) but let screen turn off normally
- Alarm repeats on lock screen every 3s until dismissed, without re-waking the device

## Constraints & Preferences
- Alarm must wake device and show alarm UI (`fullScreenIntent: true`) on first fire
- Repeating alarms (every 3s) should have sound/vibration but no screen-wake
- App must NOT render over lock screen when no alarm is active
- Lock screen should show trip info (destination + distance) when tracking
- Both real GPS and simulation tracking must work on lock screen
- CPU must stay alive during lock (PARTIAL_WAKE_LOCK), but screen must turn off normally
- WakelockPlus must be removed from Dart (was keeping screen on)

## What was done
1. Guarded `didChangeAppLifecycleState` polling restart with `trip.isActive` check — prevents `_updateDistance()` re-firing alarm on resume
2. Made `triggerAlarm()` idempotent (`if (state!.hasAlerted) return;`) — both GeofenceManager and `_updateDistance` can call it, only first fires
3. Simulation `_pollTimer` no longer cancelled on pause — keeps running in background
4. Removed all `WakelockPlus.enable()` calls from `active_trip_screen.dart`
5. Added native `PARTIAL_WAKE_LOCK` in `TrackingForegroundService.kt` (CPU-on, screen-off)
6. Removed `showWhenLocked` + `turnScreenOn` from `AndroidManifest.xml` lines 26-27
7. Added `VISIBILITY_PUBLIC` to tracking notification in `TrackingForegroundService.kt`
8. Added `ForegroundServiceChannel.stopTracking()` call in `AlarmScreen._dismiss()` for trip completion
9. Changed notification response handler in `main.dart` from `pushNamed` to `pushReplacementNamed`
10. Added `fullScreenIntent` parameter to `AlarmNotificationService.showAlarmNotification()` — defaults `true` for initial wake
11. Repeating alarm in `AlarmScreen._startRepeatingAlarm()` calls with `fullScreenIntent: false` (sound/vibration only)
12. Removed `WidgetsBindingObserver` from `AlarmScreen` — repeating timer stays alive on lock screen until dismissed

## Verification
- `flutter analyze`: 0 errors, 3 info (pre-existing)
- `flutter build apk --debug`: succeeded

## Key decisions
- Native `PARTIAL_WAKE_LOCK` over `WakelockPlus` for reliable CPU-keepalive (screen-off)
- `showWhenLocked`/`turnScreenOn` removed because `fullScreenIntent` on notifications is the sole wake mechanism
- Initial alarm = `fullScreenIntent: true` (wake device), repeating = `fullScreenIntent: false` (sound only)
- `WidgetsBindingObserver` removed from AlarmScreen; timer runs unconditionally on lock screen
- `triggerAlarm()` idempotent guard prevents duplicate notifications from parallel GPS listeners

## Critical Context
- Two parallel GPS listeners: `GeofenceManager._checkPosition()` + `ActiveTripScreen._updateDistance()` — both can call `triggerAlarm()`.
- `TrackingForegroundService.kt` is the single service for real + simulation tracking; acquires `PARTIAL_WAKE_LOCK` in `onCreate`, releases in `onDestroy`.
- `fullScreenIntent: true` on alarm notification is the ONLY mechanism that brings app over lock screen.
- For simulation: `_pollTimer` keeps running in background; for real GPS it's cancelled and GeofenceManager handles detection.
- `AlarmScreen._dismiss()` for last stop calls `ForegroundServiceChannel.stopTracking()` which kills the wakelock.

## Relevant Files
- `android/app/src/main/AndroidManifest.xml` — removed `showWhenLocked`/`turnScreenOn`
- `android/app/src/main/kotlin/com/stopco/stop_co/TrackingForegroundService.kt` — added PARTIAL_WAKE_LOCK + VISIBILITY_PUBLIC
- `lib/features/trip/presentation/active_trip_screen.dart` — lifecycle guard, simulation bg polling, removed WakelockPlus
- `lib/features/trip/presentation/alarm_screen.dart` — removed WidgetsBindingObserver, fullScreenIntent:false on repeat, ForegroundServiceChannel.stopTracking
- `lib/features/trip/data/alarm_notification_service.dart` — fullScreenIntent parameter
- `lib/features/trip/data/trip_providers.dart` — idempotent triggerAlarm()
- `lib/main.dart` — pushReplacementNamed for notification response

---

# Session: Font compaction — Plus Jakarta Sans, reduced sizes, VisualDensity, modern buttons

## Goal
- Compact the app spacing, replace Inter with Plus Jakarta Sans, and modernize button styling for a minimal look.

## Constraints & Preferences
- Font: Plus Jakarta Sans (switched from Manrope after initially choosing it)
- Compaction level: Moderate (button 56→48px, card padding 16→12, input 56→48, section gaps 24→16, global VisualDensity -1)
- All button types get the reduced height
- Font sizes reduced: body 16→15, secondary 14→13, caption 12→11, sectionHeader 18→16, title 24→22, largeTitle 34→30
- Button style: 15px w500 font, 18px icons, 0.5px outlined border, 0.98 scale animation, loading spinner 20px

## What was done
- Switched `app_typography.dart` from `GoogleFonts.inter()` to `GoogleFonts.plusJakartaSans()` with reduced font sizes and w500 button weight
- Compacted `app_spacing.dart` tokens (xs=6, sm=10, md=12, lg=16, xl=24, xxl=36, buttonHeight/inputHeight=48, iconButtonSize/minTapTarget=44)
- Added `visualDensity: VisualDensity(horizontal: -1, vertical: -1)` to both light/dark themes in `app_theme.dart`
- Updated outlined button border from 1.5px→0.5px and text button theme (removed minimumSize, added padding)
- Modernized `app_button.dart`: scale 0.97→0.98, icon 20→18, outlined border 1→0.5, loading spinner 24→20 with stroke 2.5→2, removed shape from TextButton
- Removed 2 redundant `VisualDensity.compact` overrides in `destination_setup_screen.dart`
- Removed `VisualDensity(-2,-1)` override in `community_feed_tab.dart`
- Tightened button-area padding in 4 screens (`auth_screen.dart`, `alarm_screen.dart`, `trip_complete_screen.dart`, `onboarding_screen.dart`)

## Key decisions
- **Plus Jakarta Sans over Inter**: More contemporary geometric sans-serif that pairs well with compact spacing.
- **Moderate over light/aggressive compaction**: Balances density with readability; avoids negative effects of more aggressive density.
- **All buttons compacted uniformly**: Consistent visual language across primary, secondary, tonal, and text variants.
- **TextButton without explicit minimumSize**: Minimal appearance, padding-only for tap target; inherits height from content and density.

## Next Steps
- Monitor runtime font download for Plus Jakarta Sans (loaded via `google_fonts` at first launch)
- Verify layout of any screen with hardcoded inline paddings not using `AppSpacing` tokens

## Pending: Tile consistency pass
A comprehensive inventory revealed inconsistent border radii across all tappable surfaces. AppButton is the reference at **14px** flat, but nothing else aligns:

| Component | Current Radius | Target |
|---|---|---|
| **AppButton** (reference) | 14px | — |
| ChoiceChips (dest_setup) | ~20px pill (default M3) | 14px |
| ChoiceChips (settings) | 8px | 14px |
| ChoiceChips (simulation) | 8px | 14px |
| **AppCard** (all tiles) | 16px (radiusLg) | 14px |
| PostCard | 12px + 0.5 elev | 14px, flat |
| CoordinateChip | 8px | 14px |
| SimulationBadge pills | 8px | 14px |
| SegmentedButtons | ~12px (M3 default) | 14px |
| ResetButton (settings) | raw TextButton | AppButton(isText) |

### To do before this pass
1. Decide: should tappable tiles (AppCard onTap, PostCard, etc.) get the scale 0.98 + haptic treatment, or stay as plain InkWell ripple?
2. Decide: should PostCard keep its unique 0.5 elevation or go flat?

### Changes needed
- Add `AppSpacing.tileRadius = 14` token
- Update AppButton to reference `AppSpacing.tileRadius`
- Add custom `shape` to ChoiceChips in `destination_setup_screen.dart` (3 locations: single-stop, edit sheet, waypoint edit sheet)
- Update ChoiceChip shape in `settings_screen.dart` (radiusSm → tileRadius)
- Update ChoiceChip shape in `simulation_screen.dart` (radiusSm → tileRadius)
- Change `AppCard` theme radius from `radiusLg=16` → `tileRadius=14`
- Update PostCard radius from `radiusMd=12` → `tileRadius=14`; remove 0.5 elevation
- Update CoordinateChip from `radiusSm` → `tileRadius`
- Update SimulationBadge speed pills from `radiusSm` → `tileRadius`
- Override SegmentedButton shapes in settings and community to use `tileRadius`
- Replace raw `TextButton` in `settings_screen.dart` `_ResetButton` with `AppButton(isText: true)`

## Critical Context
- All three `AppTypography` getters are non-`const` (runtime `GoogleFonts.plusJakartaSans()` calls), so fallback const text styles are retained for scenarios needing const
- `flutter analyze` passes with 0 errors (3 pre-existing info warnings only)
- `flutter build apk --debug` succeeds

## Relevant Files
- `lib/core/theme/app_typography.dart`: All text styles — font family, sizes, weights, fallbacks
- `lib/core/theme/app_spacing.dart`: All spacing tokens (padding, gaps, button/input heights, radii)
- `lib/core/theme/app_theme.dart`: Light and dark theme data, button themes, global VisualDensity
- `lib/core/components/app_button.dart`: FilledButton/OutlinedButton/TextButton/FilledButton.tonal wrappers with scale animation, loading state, icon support
- `lib/features/auth/presentation/auth_screen.dart`: Button-area padding tightened
- `lib/features/trip/presentation/alarm_screen.dart`: Button-area padding tightened
- `lib/features/trip/presentation/trip_complete_screen.dart`: Button-area padding tightened
- `lib/features/onboarding/presentation/onboarding_screen.dart`: Button-area padding tightened
- `lib/features/destination/presentation/destination_setup_screen.dart`: Removed redundant VisualDensity overrides on ChoiceChips
- `lib/features/community/presentation/community_feed_tab.dart`: Removed redundant VisualDensity override on SegmentedButton

---

# Session: POI markers (abandoned) + Nominatim search location bias fix

## Goal
- Add tappable landmark POI markers on Flutter Map (OpenStreetMap) using Overpass API, with drag-to-adjust pins and location-biased search

## Constraints & Preferences
- Use Overpass API (free, no key) for POI data
- POIs must be tappable → add as waypoint in destination planner
- POI markers show emoji + name label, limited to 5 results, prioritized by landmark tier
- Pin can be long-pressed and dragged to adjust location
- Search results biased near user's GPS location
- API limits must be respected — final decision: remove POI overlay entirely due to Overpass 406/429/403 issues (even after User-Agent fix)

## Progress
### Done
- Created POI data layer (model, Overpass service with fallback servers, Riverpod providers)
- Created POI UI (emoji+name marker widget, info bottom sheet)
- Integrated POI markers into destination_setup_screen, active_trip_screen, trip_detail_screen
- Added long-press drag to reposition waypoint pins
- Swapped marker z-order so waypoints render on top of POI labels
- Biased Nominatim search results near user location via `&viewbox=` param
- Fixed Overpass 406 errors with raw string body, Accept header, User-Agent, GET fallback, 12s timeout
- Limited POI results to 5 with priority sorting (tier 1 landmarks first)
- Removed all POI watching/markers/imports from all three screens to stop API calls

### In Progress
- (none)

### Blocked
- (none)

## Key Decisions
- Removed POI overlay entirely: Overpass servers persistently returned 406/429/403 even with proper User-Agent and fallback chain — not worth the API burden
- POI source files kept in project (poi/ directory with model, service, providers, UI) for future re-enablement if a more reliable POI source is chosen
- Long-press drag kept — unrelated to POI, still useful for pin adjustment
- Location-biased search kept — uses existing Nominatim 1 req/s call, no extra API cost
- `viewbox` parameter over `lat`/`lon`: `lat`/`lon` are display hints only, `viewbox` (2° × 2° bounding box around user, no `bounded=1`) actually biases search scores toward nearby results with out-of-area fallback

## Next Steps
- (none — POI abandoned, search bias fixed)

## Critical Context
- Overpass error log: all 3 servers failed — `POST overpass-api.de → 406`, `POST kumi.systems → 429`, `POST bplaced.net → 403`; even GET + User-Agent didn't resolve fully
- Overpass daily limit: ~10k req/IP with User-Agent
- Nominatim rate limit: 1 req/s (unchanged)
- OSRM routing: unlimited for non-commercial
- User-Agent string used: `AppConstants.userAgent` → value from `.env` (default `StopCo/1.0`)

## Relevant Files
- `lib/features/poi/`: entire POI feature — data/poi.dart (model), data/overpass_service.dart (service with fallback), data/poi_providers.dart (Riverpod + priority sort), presentation/poi_marker_layer.dart (emoji+name labels), presentation/poi_bottom_sheet.dart (info sheet) — all kept but not imported by any screen
- `lib/features/destination/data/geocoding_service.dart`: changed `lat`/`lon` → `viewbox=$minLon,$minLat,$maxLon,$maxLat` for actual location-biased search

---

# Session: Airbnb redesign + custom alarm notification fix + alarm test in Simulation

## Goal
- Implement Airbnb-style travel/navigation redesign (new primary color, soft dark mode, flattened nav, pill buttons, card shadows)
- Add alarm sound testing to Simulation screen
- Fix custom alarm notification playback on Android (system_server can't read app-private URIs)

## Constraints & Preferences
- Final primary color: warm teal-blue `#4A90B0` (light) / `#3A7A9A` (dark)
- Dark mode softened: scaffold `#26262A`, surface `#2E2E32`, containers `#38383C`/`#424246`
- Bottom nav: uniform 4 tabs, no gradient pill, coral active dot, opaque surface, 0.5px top border
- All buttons pill-shaped (`pillRadius = 100`)
- Font letterSpacing all `0` (except display styles)
- Custom alarm fix: copy selected audio to MediaStore (API 29+) so system_server can read it
- No new Android permissions needed

## What was done
1. **Airbnb redesign**: `app_colors.dart` (primary=#4A90B0, primaryDark=#3A7A9A, taupe=#8B7E74), `app_spacing.dart` (pillRadius=100), `app_typography.dart` (letterSpacing all 0), `app_theme.dart` (teal-blue primary, taupe secondary, card elevation 2, pill buttons), `app_button.dart` (pill shape), `app_card.dart` (elevation from cardTheme), `main_shell.dart` (flattened nav, coral dot, opaque bg, 0.5px border)
2. **Softened dark mode**: lighter surface/container colors, outlineVariant=#424246, divider at 12% opacity
3. **audioplayers** dependency added
4. **Test Alarm Sound** button in Simulation screen — plays custom sound in-app via audioplayers
5. **Fixed custom alarm notification**: `MainActivity.kt` — `copyToMediaStore()` (API 29+) returns MediaStore `content://` URI that system_server can read; internal copy kept for audioplayers test; `copyToInternalStorage` return type → `Unit`

## Verification
- `flutter analyze`: 0 errors, 3 pre-existing info warnings
- `flutter build apk --debug`: succeeds

## Key decisions
- **MediaStore over FileProvider/grantUriPermission**: Most reliable approach — `system_server` (UID 1000) can always read MediaStore URIs; no new Android permissions needed on API 29+
- **Internal copy retained**: audioplayers `UrlSource` can read app-private files (same UID) — keeps in-app test working
- **No Android permissions needed**: `takePersistableUriPermission` is programmatic; MediaStore access on API 29+ doesn't require `WRITE_EXTERNAL_STORAGE`
- **Pill buttons**: unified look via `AppSpacing.pillRadius = 100` on all button types

## Critical Context
- `system_server` (UID 1000) cannot read `file://` in app-private storage or document-picker `content://` URIs — fix copies to MediaStore on API 29+
- On API 24–28, notification falls back to default sound (audioplayers test still works with file path)
- To test: must re-pick alarm sound in Settings after installing (old file paths stored before fix won't work)

## Relevant Files
- `lib/core/theme/app_colors.dart` — primary=#4A90B0, primaryDark=#3A7A9A, taupe=#8B7E74
- `lib/core/theme/app_spacing.dart` — pillRadius=100
- `lib/core/theme/app_theme.dart` — teal-blue ColorScheme, card elevation 2, pill shapes
- `lib/core/theme/app_typography.dart` — all letterSpacing set to 0
- `lib/core/components/app_button.dart` — pill shape via AppSpacing.pillRadius
- `lib/core/components/app_card.dart` — elevation from cardTheme
- `lib/features/home/presentation/main_shell.dart` — flattened nav, coral dot, opaque bg, 0.5px border
- `lib/features/simulation/presentation/simulation_screen.dart` — "Sound" section + Test Alarm button
- `android/app/src/main/kotlin/com/stopco/stop_co/MainActivity.kt` — `copyToMediaStore()`, `detectExtension()`
- `pubspec.yaml` — added `audioplayers: ^6.1.0`

---

# Session: Keyboard-aware bottom sheets — no overflow, auto push above keyboard

## Goal
- Fix keyboard overlapping destination input fields in the planner bottom sheet. Use `SingleChildScrollView` so content is scrollable when keyboard covers it, and add `viewInsets.bottom` to padding + `maxHeight` so sheet shifts up by the keyboard height without overflow.

## What was done
1. Added `resizeToAvoidBottomInset: false` to `DestinationSetupScreen` Scaffold (already set) — map doesn't resize when keyboard opens.
2. Wrapped planner bottom sheet child with `SingleChildScrollView` — content scrollable when keyboard covers it.
3. Added `MediaQuery.of(context).viewInsets.bottom` to both `padding.bottom` and `maxHeight` — sheet pushes up by keyboard height, and the `maxHeight` constraint grows by the same amount, preventing overflow.
4. Same pattern applied to edit bottom sheet (`_buildEditBottomSheet`): `viewInsets.bottom` in padding + `SingleChildScrollView`.
5. Verified: `flutter analyze` — 0 errors, `flutter build apk --debug` — succeeds, `adb install` — success.

## Key decisions
- `viewInsets.bottom` in padding + `maxHeight` both increase by keyboard height: sheet slides up exactly as much as it needs, the available content area stays the same, no overflow.
- `SingleChildScrollView` as fallback — if content is still taller than the adjusted maxHeight, user can scroll.

## Relevant Files
- `lib/features/destination/presentation/destination_setup_screen.dart` — `_buildPlannerBottomSheet` and `_buildEditBottomSheet` updated with keyboard-aware padding, adjusted maxHeight, and SingleChildScrollView.

---

# Session: Battery optimization, Schedule Trip button, tagline, simulation lifecycle fix, map/GPS bug fix

## Goal
- Optimize battery usage (background tracking, alarms, foreground service) when app is minimized and when opened; refactor Schedule Trip button arrangement in destination setup screen; fix simulation alarm on display-off; update app tagline; fix map not showing and GPS not producing data after latest build.

## Constraints & Preferences
- All battery optimization changes must not compromise existing app features (alarm, tracking, trip recording, navigation, simulation)
- User accepted adaptive GPS accuracy: `medium` when far (> 2× radius), `high` when close (≤ 2× radius), `bestForNavigation` at arrival
- User wants "Schedule Trip" highlighted (primary filled button) and "Start Trip" de-emphasized (TextButton) when entering DestinationSetupScreen from Schedules context
- User wants auto-close to Schedules list after scheduling a trip
- Tagline changed to "For commuters, by commuters"
- Simulation timer must keep running when display is off (lifecycle-independent)

## What was done
1. Merged GeofenceManager dual GPS listeners into single stream handler; removed `geofenceManagerProvider` usage from `active_trip_screen.dart`
2. Removed redundant 10 s polling timer for real GPS (kept simulation 1 s timer)
3. Implemented adaptive GPS accuracy tier switching inside `_updateAccuracyTier()` with stream recreation
4. Removed periodic 60 s timer-based route re-fetch; now calls `_maybeReFetchRoute()` from every position update (movement-based only)
5. Throttled foreground notification updates to 30 s interval in `_updateDistance()`
6. Added `RepaintBoundary` wrapping FlutterMap
7. Created `BatteryOptChannel` (Dart) and battery MethodChannel in `MainActivity.kt` (`com.stopco.app/battery`) with `requestBatteryOptimizationExemption` and `isIgnoringBatteryOptimizations`
8. Integrated battery optimization dialog before trip start in both real and simulation modes via `_checkBatteryOptimization()`
9. Added `showScheduledTrip` parameter (`default false`) to `DestinationSetupScreen`
10. Flipped button priority in `_buildSingleStopPanel()` and `_buildWaypointList()` when `showScheduledTrip == true`: "Schedule Trip" → primary AppButton, "Start Trip" → secondary TextButton
11. Updated `_scheduleTrip()` to auto-pop to Schedules list when `showScheduledTrip == true`
12. Updated `main_shell.dart` FAB to pass `showScheduledTrip` based on selected segment
13. Updated `schedules_list_view.dart` empty-state button to pass `showScheduledTrip: true`
14. Changed tagline from `"Don't miss your stop"` to `"For commuters, by commuters"` in `app_brand.dart`, `brand_intro_screen.dart`, and settings description
15. Made `didChangeAppLifecycleState` a no-op so simulation 1 s timer runs independently of lifecycle (fixes alarm not firing on display-off)
16. **Bug fix**: Made `_checkBatteryOptimization()` non-blocking — moved it after tracking starts without `await` (was blocking GPS stream creation from `initState` via `showDialog` throwing before widget tree was built)
17. **Bug fix**: Added `simulationEnabled` guard in `_updateAccuracyTier()` to prevent creating a GPS stream subscription during simulation mode (was activating GPS hardware unnecessarily)

## Key decisions
- Adaptive accuracy switching over fixed high accuracy: battery savings (high→medium) when far from destination
- `_checkBatteryOptimization()` fire-and-forget after tracking starts: GPS stream is never blocked by dialog lifecycle
- `RepaintBoundary` on FlutterMap: prevents unnecessary repaints when app is in background
- Battery optimization dialog shown before first trip only (per app session via `batteryOptAskedProvider`)

## Verification
- `flutter analyze`: 0 errors, 3 pre-existing info warnings
- `flutter build apk --debug`: succeeded

## Bug Root Cause
After the battery optimization changes, `_startMonitoring()` called `await _checkBatteryOptimization()` before creating the GPS stream. `checkBatteryOptimization()` calls `showDialog`, which can fail with an unhandled async exception when called during `initState` (widget tree not fully built). This caused the entire `_startMonitoring` chain to terminate early — no stream was created, `_currentPosition` remained null, map never rendered, and GPS never produced data. Fixed by moving the battery check after tracking starts without `await`.

## Second Bug
During simulation mode, `_updateDistance()` called `_updateAccuracyTier()`, which created a `Geolocator.getPositionStream()` subscription when the accuracy tier changed. This activated GPS hardware unnecessarily during simulation and could conflict with simulation position data. Fixed by adding `if (ref.read(simulationEnabledProvider)) return;` guard.

## Next Steps
- No specific next steps — battery optimization and bug fixes complete

## Relevant Files
- `lib/features/trip/presentation/active_trip_screen.dart` — main file: `_startMonitoring()` restructured, `_checkBatteryOptimization()` non-blocking, `_updateAccuracyTier()` simulation guard, adaptive accuracy, lifecycle no-op, RepaintBoundary, notification throttle
- `lib/features/trip/data/location_service.dart` — `getPositionStream()` accepts `accuracy`/`distanceFilter` parameters
- `lib/core/platform/battery_opt_channel.dart` — NEW: Dart MethodChannel wrapper for battery exemption
- `lib/features/destination/presentation/destination_setup_screen.dart` — added `showScheduledTrip` param, flipped button priority, auto-close on schedule
- `lib/core/components/app_brand.dart` — tagline changed
- `lib/features/onboarding/presentation/brand_intro_screen.dart` — tagline changed
- `android/app/src/main/kotlin/com/stopco/stop_co/MainActivity.kt` — added `com.stopco.app/battery` MethodChannel handler
- `lib/features/scheduled_trip/presentation/schedules_list_view.dart` — passes `showScheduledTrip: true`
- `lib/features/home/presentation/main_shell.dart` — FAB passes `showScheduledTrip` by segment

---

# Session: Battery optimization analysis — departure notifications vs. arrival geofence

## Goal
- Analyze battery consumption for scheduled trip departure-time notifications and the existing arrival geofence alarm system.

## Battery profile: departure-time notification (new feature)
- **Virtually free.** A one-shot local notification at a specific date/time via `flutter_local_notifications` `zonedSchedule()` uses Android's native `AlarmManager` under the hood. No GPS, no stream, no wakelock needed. The app doesn't need to be running.
- **No optimization needed** for this feature.

## Battery profile: arrival geofence alarm (existing — the real drain)
- The current implementation streams continuous GPS via `Geolocator.getPositionStream()` for the entire trip duration. This is the #1 battery consumer.
- Adaptive accuracy (medium → high → bestForNavigation) helps but doesn't change the fundamental approach — GPS hardware is always active.

## Optimization options (ordered by impact)

### Option A: Android GeofencingClient API (high impact, recommended)
- Replace the continuous Dart-level GPS stream with Android's native `GeofencingClient`.
- Registers geofence circles (one per waypoint). Android's fused location provider:
  - Uses WiFi/cell tower triangulation when far from a geofence (near-zero battery)
  - Only turns on GPS when you're close to a geofence boundary
  - Batches checks with other apps' geofence requests
- **Estimated savings:** 60–80% reduction in GPS-on time.
- **Implementation:** New Kotlin file or extend `TrackingForegroundService.kt`; Dart MethodChannel to register/unregister geofences; callback on geofence enter → triggers alarm. Fallback to Dart-level stream if GeofencingClient unavailable.

### Option B: Lighter accuracy tiers (medium impact)
- Could go further than current implementation:

| Current | Proposed |
|---|---|
| `medium` (50m filter) when > 2× radius | `low` (network-based, ~500m filter) when > 5× radius |
| `high` (10m filter) when ≤ 2× radius | Keep as-is |
| `bestForNavigation` (0m) at arrival | Keep as-is |

- GPS hardware off entirely when far away, using only network/cell location.

### Option C: Periodic polling instead of streaming (medium impact)
- Replace `getPositionStream()` (continuous callback on every GPS fix) with a periodic `Timer` + `getCurrentPosition()` (one-shot).
- Poll every 60s when far (> 2× radius), every 15s when approaching (≤ 2× radius), every 5s at arrival.
- GPS radio sleeps between polls instead of streaming continuously. But less responsive.

### Option D: Simulation timer reduction (low impact)
- The simulation 1s `Timer.periodic` wakes the CPU every second. Could be relaxed to 2–3s when far from next waypoint.

## Recommendation
| Priority | What | Why |
|---|---|---|
| **1** | Option A: GeofencingClient | Biggest savings, native Android optimization, standard pattern for this exact use case |
| **2** | Option B: lighter accuracy tiers | Simple code change, immediate savings with minimal risk |
| **3** | Option D: simulation timer | Cheap win during simulation only |
| — | Departure notification | No optimization needed — inherently battery-light |

## Key decisions
- `zonedSchedule()` is the right approach for departure notifications: zero battery drain until fire time.
- Continuous GPS stream is the dominant battery consumer; native GeofencingClient is the proper long-term fix.
- All four options are additive — they can be implemented independently.

## Critical Context
- `PARTIAL_WAKE_LOCK` is already acquired in `TrackingForegroundService.kt` (CPU-on, screen-off).
- WakelockPlus `enable()` has been removed — only `disable()` remains (effectively unused).
- Battery optimization exemption dialog is shown once per session via `BatteryOptChannel` — user can skip.
- Current adaptive accuracy tiers: medium (50m filter), high (10m), bestForNavigation (0m).
- Simulation correctly skips GPS hardware activation via `simulationEnabled` guard.
- Departure-time notifications for scheduled trips are purely time-based — no GPS, no streaming, no wakelock needed.

## Relevant Files
- `lib/features/trip/presentation/active_trip_screen.dart` — GPS stream, adaptive accuracy, `_updateAccuracyTier()`, notification throttle, `RepaintBoundary`, lifecycle handler
- `lib/features/trip/data/geofence_manager.dart` — orphaned class (monitoring merged into ActiveTripScreen)
- `lib/features/trip/data/location_service.dart` — `getPositionStream()` with configurable accuracy/distanceFilter
- `lib/core/platform/battery_opt_channel.dart` — Dart side of battery exemption MethodChannel
- `android/app/src/main/kotlin/com/stopco/stop_co/MainActivity.kt` — `com.stopco.app/battery` channel handler
- `android/app/src/main/kotlin/com/stopco/stop_co/TrackingForegroundService.kt` — `PARTIAL_WAKE_LOCK`, `VISIBILITY_PUBLIC`, notification update handling
