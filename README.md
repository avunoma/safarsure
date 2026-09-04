# SafarSure

**Travel protected.** White-plate private car cost-share for India — fuel + toll share, not a taxi fare.

## Features

- **Auth** — Mobile OTP (demo: any 6-digit code) or Google Sign-In (demo or Firebase)
- **Privacy** — Driver/rider names, phone, and chat hidden until a seat request is **accepted**
- **Ratings** — 1–5 stars + optional comment after a confirmed trip (both sides)
- **Chat** — Unlocks after confirmation; syncs across two phones via shared cloud (Firestore REST or SDK)
- **Places** — Inline city picker with aliases (Bangalore→Bengaluru, etc.); optional Google Places merge
- **Search sorting** — Soonest (default), lowest share price, or highest driver rating
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

## Two-phone demo (no codes — automatic discovery)

Trips, seat requests, and chat sync via **Firestore REST** (no `google-services.json` required when using demo dart-defines).

1. Create a Firebase project with Firestore (test-mode rules OK for MVP)
2. Run **both phones** with the same dart-defines:

```bash
flutter run \
  --dart-define=DEMO_CLOUD_ENABLED=true \
  --dart-define=DEMO_FIREBASE_PROJECT_ID=your-project-id \
  --dart-define=DEMO_FIREBASE_API_KEY=your-web-api-key
```

**Flow (straightforward booking):**
1. **Phone A (driver)** — login as User A → Profile → Driver → Post ride (e.g. Mumbai → Pune, tomorrow 9am)
2. **Phone B (rider)** — login as User B → Search same route/date → see Phone A's ride → Request seat
3. **Phone A** — My rides → open trip → see incoming request → Accept (within ~2s via cloud poll)
4. **Both** — chat + ratings unlock after accept; identities revealed per privacy rules

No sync codes or manual pairing required.

## Optional: Firebase + Google Sign-In

See earlier sections in repo history or enable with:

```bash
flutter run --dart-define=FIREBASE_ENABLED=true
```

## Optional: Google Places autocomplete

```bash
flutter run --dart-define=MAPS_API_KEY=your_key_here
```

## Demo walkthrough (single device)

1. **Login** — Google demo or phone OTP
2. **Rider** — Home → search → sort by Soonest / Price / Rating → request a seat
3. **Profile** → switch to **Driver**
4. **Driver** — My rides → accept request → chat + rate rider
5. **Profile** → switch back to **Rider** → My rides → see driver first name, chat, rate trip

## Analysis

```bash
flutter analyze
flutter test
```

## Out of scope

Insurance, KYC, SOS, live GPS tracking, UPI/payments, and competitor fare comparisons.
