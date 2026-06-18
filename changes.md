## Goal
- Refactor saved destinations UI, database layer (Firestore → SQLite), trip screen layout, OSM compliance, foreground notification live updates, OSRM routing, swipeable tabs, dynamic brand, and home page recommendations.

## Constraints & Preferences
- Long press on saved destination tile → selection mode for batch delete; 4 inline action buttons (Play, Star, Edit, Delete) replace triple-dot menu
- Repeated alarm → vibration + notification sound loop every 3s until dismiss, respecting AlarmType setting
- Cloud Firestore removed; local persistence via drift (SQLite) for destinations, settings
- OSM tile usage policy requires attribution + userAgentPackageName on all TileLayer usages
- Foreground notification must show "Active trip", destination name, remaining distance, and update live when app is backgrounded
- OSRM routing via public demo API (router.project-osrm.org /car profile) with periodic re-fetch (60s) and Haversine fallback; no API key needed
- Simulation should follow routed road path (polyline segments) when route coordinates are available
- Destination setup screen: "Start Trip" button saves + starts trip immediately; "Save Only" saves and pops back
- Tabs swipeable left/right via PageView (300ms animation); bottom nav stays in sync
- Brand displayed via reusable AppBrand widget (icon + AppConstants.appName); no user customization
- Home page recommendations: vertical list of saved destinations (favorites first, then by createdAt desc); empty state when no destinations exist

## Progress
### Done
- **Saved destinations UI refactor**: _DestinationTile in main_shell.dart — replaced popup with 4 inline IconButtons (Play, Star, Edit, Delete); long press enters selection mode with checkbox + batch delete bar
- **Repeated alarm looping**: AlarmScreen starts Timer.periodic(3s) that re-posts notification (sound) + HapticFeedback (vibration) based on AlarmType; timer cancelled on dismiss
- **AlarmType wiring**: AlarmNotificationService.showAlarmNotification() accepts AlarmType to control playSound/enableVibration; ActiveTripNotifier reads setting via ref
- **Database migration (Firestore → drift/SQLite)**:
  - Added drift, sqlite3_flutter_libs, path_provider deps; removed cloud_firestore
  - Created lib/core/database/database.dart — Destinations table, AppSettingsTable, DAO methods
  - Created lib/core/database/database_provider.dart — localDatabaseProvider (overridden in main.dart)
  - Rewrote DestinationRepository — Firestore CRUD → drift DAO calls; removed userId/auth dependency
  - Removed toJson()/fromJson() from Destination model
  - Updated SettingsNotifier — loads from SQLite on init, persists on every mutation
  - main.dart initializes LocalDatabase() and overrides provider in ProviderScope
  - Generated drift code via build_runner; flutter analyze passes (only pre-existing infos)
- **Cancel trip black screen fix**: ActiveTripScreen — cancel timers first in onPressed; trip == null guard returns SizedBox + uses maybePop() with canPop() check
- **Map enhancement**: MapController, destination marker, PolylineLayer (user→dest), _fitMapBounds() auto-fits camera on first position; show/hide toggle has icon
- **OSM compliance**: active_trip_screen.dart, home_screen.dart, destination_setup_screen.dart — added userAgentPackageName + SimpleAttributionWidget on all
- **Foreground notification live updates**:
  - Added updateTrackingNotification() to ForegroundServiceChannel (Dart)
  - MainActivity.kt handles updateTrackingNotification method → sends ACTION_UPDATE Intent
  - TrackingForegroundService.kt — ACTION_UPDATE handler in onStartCommand, updateNotification(), BigTextStyle ("Active trip" title, remaining distance + destination)
  - active_trip_screen.dart — calls _startForegroundService() in both monitoring paths, _updateForegroundNotification() in _updateDistance(), stopTracking() in dispose() and cancel handler
- **OSRM routing**:
  - Created lib/features/trip/domain/route_result.dart — RouteResult model (distance, duration, coordinates)
  - Created lib/features/trip/data/routing_service.dart — OSRM HTTP client via existing http package; Riverpod provider; 5s timeout; GeoJSON parsing
  - Updated lib/core/constants/app_constants.dart — added osrmBaseUrl, routeReFetchIntervalSec, routeReFetchMinDistance
  - Updated lib/features/trip/data/trip_model.dart — added RouteResult? routeResult field + copyWith
  - Updated lib/features/trip/data/trip_providers.dart — added setRouteResult() + routingServiceProvider
  - Updated lib/features/trip/presentation/active_trip_screen.dart — fetch route on first GPS position, periodic re-fetch (60s if moved >50m), draw routed polyline, OSRM attribution ("© OSM contributors · Routing by OSRM"), pass route to simulation on start
  - Updated lib/features/trip/data/location_service.dart — no-op (Haversine distance retained for alarm trigger; routed distance is display-only)
- **Route-following simulation**:
  - Updated lib/features/simulation/data/simulation_service.dart — accepts routeCoordinates parameter; _tickAlongRoute() uses tracked _currentSegIndex (never resets to 0); _tick() called immediately after timer start (no 1s initial pause); fallback to straight-line when no route
  - Updated lib/features/simulation/presentation/simulation_screen.dart — fetches OSRM route via routingServiceProvider before navigation; passes route coordinates to simulationService.start(); skips straight-line phase
- **Save & Start Trip**:
  - Updated lib/features/destination/presentation/destination_setup_screen.dart — added _saveAndStartTrip() (saves to SQLite → startTrip() → pushReplacementNamed /active-trip); _BottomPanel shows two buttons: "Start Trip" (primary, navigation icon) + "Save Only" (text link) for new destinations; edit mode unchanged (single "Update Destination" button)
- **Swipeable tabs**:
  - Updated lib/features/home/presentation/main_shell.dart — replaced IndexedStack with PageView + PageController; bottom nav onTap calls animateToPage(300ms, easeInOut); onPageChanged syncs _currentIndex; all pages kept alive
- **Dynamic brand**:
  - Created lib/core/components/app_brand.dart — AppBrand widget (notifications_active_rounded icon + AppConstants.appName text)
  - Updated lib/app.dart — title uses AppConstants.appName
  - Updated lib/features/auth/presentation/auth_screen.dart — replaced hardcoded 'Stop-Co' Text with AppBrand widget
  - Updated lib/features/settings/presentation/settings_screen.dart — replaced hardcoded 'Stop-Co' with AppConstants.appName
  - Updated lib/features/trip/data/alarm_notification_service.dart — ticker uses AppConstants.appName
  - Updated lib/features/home/presentation/main_shell.dart — _HomeTabHeader uses AppBrand for non-auth greeting
- **Home page recommendations**:
  - Updated lib/features/destination/data/destination_providers.dart — added recommendedDestinationsProvider (favorites first, then by createdAt desc)
  - Updated lib/features/home/presentation/main_shell.dart — _HomeTab header uses AppBrand; added _YourStopsSection (vertical list with star indicator + play button), _EmptyDestinationsPlaceholder (icon + message when 0 destinations); _HomeDestinationCard compact widget (icon, name, radius, favorite star, play button)
- **flutter analyze**: passes with only 3 pre-existing info-level deprecation notices in settings_screen.dart

### In Progress
- (none)

### Blocked
- (none)

## Key Decisions
- Drift/SQLite for local storage: type-safe, reactive streams, migration support, same query pattern as Firestore's snapshots
- Full-screen map background + overlay card: cleaner, map-first UX for active trip
- Foreground notification updated via ACTION_UPDATE Intent pattern: simple, no Binder/service binding needed
- OSM attribution via SimpleAttributionWidget: no extra dependency, text-only
- OSRM public demo API for routing: no API key, no new dependencies (uses existing http package), self-hostable for scaling
- Route-following simulation: tracks _currentSegIndex forward-only (never searches from 0) + immediate _tick() call to eliminate 1s initial pause
- PageView instead of IndexedStack: native swipe gesture support with 300ms easeInOut animation
- AppBrand widget as single brand source: centralized widget, easy to update, consistent across auth/settings/home
- Vertical list only for recommendations: simpler than horizontal scroll, favorites indicated by star

## Next Steps
1. Test full flow: set destination → Start Trip → active trip screen with routed polyline → background → foreground notification updates
2. Test simulation: select destination → Start Simulation → OSRM route fetched → simulation follows road path
3. Test swipeable tabs: verify state preservation (simulation running while swiping, scroll positions)
4. Verify OSRM fallback (airplane mode: polyline draws straight line, simulation uses straight-line)
5. Consider self-hosted OSRM server for production scaling (router.project-osrm.org has fair-use limits)

## Critical Context
- cloud_firestore removed from pubspec.yaml; google-services plugin kept for Firebase Auth
- OSRM endpoint: https://router.project-osrm.org/route/v1/driving/{lon1},{lat1};{lon2},{lat2}?overview=full&geometries=geojson
- OSRM returns GeoJSON where coordinates are [longitude, latitude] — reversed to LatLng(lat, lon) in routing_service.dart
- Haversine distance still used for alarm trigger (proximity check); routed distance is display-only
- Simulation restarts in _fetchRouteAndStart() when route arrives: stop() + start() with route coordinates; _isSimulating flag prevents UI flicker
- _scheduleSimulationRouteFetch() in active_trip_screen.dart has guard: skips if trip.routeResult already set (avoids duplicate fetch when SimulationScreen already got the route)
- PageView keeps all 4 tabs alive (same as IndexedStack) — no rebuild on tab switch
- recommendedDestinationsProvider uses existing isFavorite + createdAt fields; no database migration needed
- AppBrand uses AppConstants.appName which is a static const — compile-time constant, no overhead
- legacy home_screen.dart is dead code (not imported anywhere); _HomeTab in main_shell.dart is the real home

## Relevant Files
- lib/features/home/presentation/main_shell.dart: saved destinations UI (selection mode + inline buttons), _HomeTab (header, _StartTripSection, _YourStopsSection, _EmptyDestinationsPlaceholder), _HomeDestinationCard, PageView swipeable tabs
- lib/features/trip/presentation/alarm_screen.dart: repeated alarm looping with Timer.periodic
- lib/core/database/database.dart: drift schema + DAO (Destinations table, AppSettingsTable)
- lib/core/database/database_provider.dart: Riverpod provider for LocalDatabase
- lib/features/destination/data/destination_repository.dart: rewritten to use drift DAO
- lib/features/destination/data/destination_providers.dart: recommendedDestinationsProvider (favorites-first sort)
- lib/features/settings/data/settings_providers.dart: persistence via drift save/load
- lib/main.dart: drift init + ProviderScope override
- lib/features/trip/presentation/active_trip_screen.dart: full-screen map, overlay card, OSRM polyline, route fetch on GPS update, periodic re-fetch, OSRM attribution, foreground service wiring
- lib/features/trip/data/routing_service.dart: OSRM HTTP client (fetchRoute + Riverpod provider)
- lib/features/trip/domain/route_result.dart: RouteResult model
- lib/features/simulation/data/simulation_service.dart: route-following _tickAlongRoute(), immediate initial _tick(), tracked _currentSegIndex
- lib/features/simulation/presentation/simulation_screen.dart: fetch route before starting simulation
- lib/features/destination/presentation/destination_setup_screen.dart: _saveAndStartTrip(), two-button bottom panel ("Start Trip" + "Save Only")
- lib/core/platform/foreground_service_channel.dart: updateTrackingNotification()
- lib/core/components/app_brand.dart: AppBrand widget (icon + AppConstants.appName)
- android/app/src/main/kotlin/.../TrackingForegroundService.kt: ACTION_UPDATE handler, live notification
- android/app/src/main/kotlin/.../MainActivity.kt: updateTrackingNotification method channel
- lib/core/constants/app_constants.dart: appName, osrmBaseUrl, routeReFetchIntervalSec, routeReFetchMinDistance
- lib/features/trip/data/trip_model.dart: RouteResult? on ActiveTrip
- lib/features/trip/data/trip_providers.dart: setRouteResult()
- lib/app.dart: title uses AppConstants.appName
- lib/features/auth/presentation/auth_screen.dart: AppBrand widget
- lib/features/settings/presentation/settings_screen.dart: AppConstants.appName in About section
- lib/features/trip/data/alarm_notification_service.dart: AppConstants.appName in ticker
- lib/features/home/presentation/home_screen.dart: OSM compliance (dead code — kept for reference)
