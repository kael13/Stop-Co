Stop-Co is a minimalist GPS-based destination alarm for commuters. Set a destination once — get an alert when you're approaching your stop, even with the app in the background.

## Features

- Firebase Auth (Email, Google, Guest)
- Add destinations by searching or tapping the map
- Saved destinations list
- One-tap start trip with adjustable alert radius
- Background geofencing via Android foreground service
- Full-screen alarm with sound, vibration, and distance display

## Prerequisites

- Flutter 3.44+ (Dart 3.12+)
- Firebase project with Authentication (Email/Password, Google, Anonymous) and Firestore

## Setup

```sh
cp .env.example .env          # create environment config
flutter pub get               # install dependencies
```

Place your Firebase config at `android/app/google-services.json`, then:

```sh
flutter run                   # run on connected device
flutter build apk --release   # release build
```

## Architecture

Feature-first with Riverpod state management:

```
lib/
  core/              # Theme, components, constants, platform channels
  features/
    auth/            # Authentication (Email, Google, Guest)
    home/            # Main navigation shell
    destination/     # Destination CRUD, map, search
    trip/            # Active trip, geofencing, alarm
    settings/        # Appearance, alert preferences
    simulation/      # GPS simulation for testing
```
