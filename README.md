# SafarSure

**Travel protected.** White-plate private car cost-share for India — fuel + toll share, not a taxi fare.

## Features

- **Auth** — Mobile OTP (demo: any 6-digit code) or Google Sign-In (demo or Firebase)
- **Privacy** — Driver/rider names, phone, and chat hidden until a seat request is **accepted**
- **Ratings** — 1–5 stars + optional comment after a confirmed trip (both sides)
- **Chat** — Unlocks after confirmation between rider and driver (local storage for demo)
- **Places** — Google Places autocomplete when `MAPS_API_KEY` is set; local city fallback otherwise
- **Leaving soon** — Trips departing in the next 2 hours on Home + search filter
- **Dual role** — Rider / Driver switch in Profile on one install

## Prerequisites

- Flutter SDK stable (3.47+ recommended)
- Android Studio / Xcode for device builds

## Quick start (demo mode — no keys required)

```bash
git clone https://github.com/avunoma/safarsure.git
cd safarsure
flutter pub get
flutter run
```

Demo login:
1. **Google (demo)** — tap "Continue with Google (demo)" on the login screen
2. **Phone OTP** — enter name + 10-digit phone, then any 6-digit OTP (`123456` works)

## Optional: Firebase + Google Sign-In

1. Create a Firebase project and add Android + iOS apps (`com.safarsure.safarsure`)
2. Download config files (do **not** commit them):
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. Run FlutterFire CLI and copy the generated file:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   cp lib/firebase_options.dart lib/firebase_options.dart  # keep local only
   ```
4. Enable **Google** sign-in in Firebase Authentication
5. Add Google Services plugin to `android/app/build.gradle` (see Firebase docs)
6. Run with Firebase enabled:
   ```bash
   flutter run --dart-define=FIREBASE_ENABLED=true
   ```

Without `FIREBASE_ENABLED=true` or config files, the app uses demo auth.

## Optional: Google Places autocomplete

1. Enable **Places API** in Google Cloud Console
2. Restrict the key to Places API + your app bundle IDs
3. Run with:
   ```bash
   flutter run --dart-define=MAPS_API_KEY=your_key_here
   ```

Without a key, pickup/drop fields fall back to a small local Indian city list.

## Demo walkthrough

1. **Login** — Google demo or phone OTP
2. **Rider** — Home → Leaving soon or search (try typed place names) → request a seat
3. **Profile** → switch to **Driver**
4. **Driver** — My rides → accept request → chat + rate rider
5. **Profile** → switch back to **Rider** → My rides → see driver first name, chat, rate trip

## Project structure

```
lib/
├── core/           # config, theme, router, firebase, places, privacy utils
├── data/           # models, repository, seed data
└── features/
    ├── auth/       # login, OTP, Google
    ├── chat/       # post-confirm messaging
    ├── home/       # leaving soon, search CTA
    ├── profile/    # role switch, ratings display
    ├── ratings/    # post-trip star rating
    ├── requests/   # seat request & status
    ├── search/     # trip search & results
    └── trips/      # trip details, post ride, driver requests
```

## Tech stack

- Flutter Material 3 · Riverpod · go_router · shared_preferences
- Optional: firebase_core, firebase_auth, google_sign_in
- Places: Google Places API via `http` (when key provided)

## Analysis

```bash
flutter analyze
flutter test
```

## Out of scope

Insurance, KYC, SOS, live GPS tracking, UPI/payments, and competitor fare comparisons.
