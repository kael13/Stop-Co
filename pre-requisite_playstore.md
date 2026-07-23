# App Release Prerequisites — Google Play Store

| # | Prerequisite | Status | Action needed |
|---|---|---|---|
| 1 | Keystore (`upload-keystore.jks` + `key.properties`) | ✅ Done | Already gitignored, release signing wired in `build.gradle.kts` |
| 2 | ProGuard / R8 rules | ⚠️ Optional | Add keep rules for Firebase, Drift if using reflection |
| 3 | Version bump (`pubspec.yaml`) | ⚠️ Before release | Increment `1.0.0+1` |
| 4 | App icon (all densities) | ⚠️ Verify | Check `@mipmap/ic_launcher` |
| 5 | Privacy Policy | ✅ Done | Located at `PRIVACY_POLICY.md` |
| 6 | Play Console listing | ❌ Missing | Create app, fill description, category, content rating |
| 7 | Build AAB | ⚠️ Final step | `flutter build appbundle --release` |

## Privacy Policy

Already written at `PRIVACY_POLICY.md`. Paste its contents into Play Console's privacy policy field.
