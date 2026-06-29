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
