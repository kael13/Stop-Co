# Stop-Co

A minimalist GPS-based destination alarm app for commuters. Never miss your stop again.

## Prerequisites

- Flutter 3.44+ (Dart 3.12+)
- Firebase project with Authentication (Email/Password, Google, Anonymous) and Firestore enabled

## Setup

1. **Create a Firebase project** at https://console.firebase.google.com

2. **Enable Authentication methods:**
   - Email/Password
   - Google Sign-In
   - Anonymous (Guest)

3. **Create a Firestore database** in your Firebase project

4. **Register your Android app** in Firebase and download `google-services.json`:
   - Place it at `android/app/google-services.json`

5. **Install dependencies:**
   ```sh
   flutter pub get
   ```

6. **Run the app:**
   ```sh
   flutter run
   ```

## Build

```sh
flutter build apk --debug
flutter build apk --release
```

## Architecture

```
lib/
  core/              # Shared theme, components, constants, platform channels
    theme/           # Colors, typography, spacing, theme data
    components/      # AppButton, AppCard, AppInput
    platform/        # Foreground service MethodChannel
    constants/       # App-wide constants
    utils/           # GPS utilities (distance calc, validation)
  features/
    auth/            # Auth (Email, Google, Guest)
    home/            # Home screen
    destination/     # Destinations (CRUD, map, search)
    trip/            # Active trip, geofencing, alarm
```

## Phase 1 Features

- Firebase Authentication (Email/Password, Google, Guest)
- Destination management (add via map tap or search, save, list)
- Trip system (start from saved destination, cancel)
- Geofencing via location polling (accuracy-filtered GPS)
- Android foreground service for background tracking
- Full-screen alarm with distance display
- Minimalist tactile UI design system

## Status

Phase 1 MVP — Core validation. See `PhasePlans.md` for full roadmap.
