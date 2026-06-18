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
