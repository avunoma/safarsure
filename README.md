# SafarSure

**Travel protected.** White-plate private car cost-share for India — fuel + toll share, not a taxi fare.

## Features

- **Auth** — Mobile OTP (demo: any 6-digit code) or Google Sign-In (demo or Firebase)
- **Privacy** — Driver/rider names, phone, and chat hidden until a seat request is **accepted**
- **Ratings** — 1–5 stars + optional comment after a confirmed trip (both sides)
- **Chat** — Unlocks after confirmation; syncs across two phones via shared cloud (Firestore REST or SDK)
- **Places** — Inline city picker with aliases (Bangalore→Bengaluru, etc.); optional Google Places merge
- **Leaving soon** — Trips departing in the next 2 hours on Home + search filter
- **Dual role** — Rider / Driver switch in Profile on one install

## Prerequisites

- Flutter SDK stable (3.47+ recommended)
- Android Studio / Xcode for device builds

## Quick start (demo mode — single device, no keys)

```bash
git clone https://github.com/avunoma/safarsure.git
cd safarsure
flutter pub get
flutter run
```

Demo login:
1. **Google (demo)** — tap "Continue with Google (demo)" on the login screen
2. **Phone OTP** — enter name + 10-digit phone, then any 6-digit OTP (`123456` works)

City search works offline: tap Pickup → full city list appears; type `ban` → Bengaluru (Bangalore).

## Two-phone demo (shared cloud)

Requests, trips, and chat sync via **Firestore** (REST when Firebase SDK is not configured). No `google-services.json` needed for REST mode.

Published trips are upserted to the `trips` collection (driver name omitted; aggregate rating kept). Other devices merge cloud trips on init and every 2s poll, so search finds newly posted rides.

1. Create a Firebase project (or use a shared team demo project) with Firestore in **test mode** / open rules for MVP
2. Enable Firestore API; copy the **Web API key** and **project ID** (client keys are not server secrets)
3. Run on both phones with the same dart-defines:

```bash
flutter run \
  --dart-define=DEMO_CLOUD_ENABLED=true \
  --dart-define=DEMO_FIREBASE_PROJECT_ID=your-project-id \
  --dart-define=DEMO_FIREBASE_API_KEY=your-web-api-key
```

**Flow:**
1. Phone A (rider) — search Bengaluru → Chennai, request a seat → note the **ride sync code**
2. Phone B (driver) — switch to Driver → **Join ride code** → enter code → accept request
3. Both phones — chat updates within ~2 seconds

With `FIREBASE_ENABLED=true` and FlutterFire config, the native Firestore SDK is used instead of REST.

## Optional: Firebase + Google Sign-In

1. Create a Firebase project and add Android + iOS apps (`com.safarsure.safarsure`)
2. Download config files (do **not** commit them):
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. Run FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Enable **Google** sign-in in Firebase Authentication
5. Run with Firebase enabled:
   ```bash
   flutter run --dart-define=FIREBASE_ENABLED=true
   ```

## Optional: Google Places autocomplete

```bash
flutter run --dart-define=MAPS_API_KEY=your_key_here
```

Google results merge into the inline city list. Without a key, the expanded local Indian city list is used.

## Demo walkthrough (single device)

1. **Login** — Google demo or phone OTP
2. **Rider** — Home → search (type `Bangalore` for Bengaluru trips) → request a seat
3. **Profile** → switch to **Driver**
4. **Driver** — My rides → accept request → chat + rate rider
5. **Profile** → switch back to **Rider** → My rides → see driver first name, chat, rate trip

## Project structure

```
lib/
├── core/           # config, theme, router, firebase, places, cloud sync, privacy
├── data/           # models, repository, seed data
└── features/
    ├── auth/       # login, OTP, Google
    ├── chat/       # post-confirm messaging (cloud + local cache)
    ├── home/       # leaving soon, search CTA
    ├── profile/    # role switch, ratings display
    ├── ratings/    # post-trip star rating
    ├── requests/   # seat request & status
    ├── search/     # trip search & results
    └── trips/      # trip details, post ride, driver requests
```

## Analysis

```bash
flutter analyze
flutter test
```

## Out of scope

Insurance, KYC, SOS, live GPS tracking, UPI/payments, and competitor fare comparisons.
