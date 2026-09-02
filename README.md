# SafarSure

**Travel protected.** A BlaBlaCar-style carpool MVP for India — safety-first intercity ride sharing with mock/local data (no backend required).

## Features

- **One app, two roles** — switch between Rider and Driver in Profile
- **Rider flow** — phone + OTP login, search trips, request seats, track request status
- **Driver flow** — post rides, accept/decline incoming seat requests
- **Mock data** — 8 sample trips across Indian city pairs; data persists locally via `shared_preferences`
- **Material 3** — deep teal primary (`#0F6B5C`), gold accent, charcoal text

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, 3.6+)
- Android Studio / Xcode for device emulators (or a physical device)

## Getting started

```bash
# Clone the repo
git clone https://github.com/avunoma/safarsure.git
cd safarsure

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### Android

```bash
flutter run -d android
```

Ensure an Android emulator is running or a device is connected (`flutter devices`).

### iOS (macOS only)

```bash
cd ios && pod install && cd ..
flutter run -d ios
```

Requires Xcode and CocoaPods on a Mac.

## Demo walkthrough

1. **Login** — enter name + 10-digit phone (`+91`), then any 6-digit OTP (demo code: `123456`)
2. **Rider** — tap "Where to?", search e.g. Bengaluru → Chennai for today, pick a trip, request a seat
3. **Switch role** — Profile → toggle **Driver**
4. **Driver** — post a ride or open **My rides** → view incoming requests → Accept / Decline
5. **Rider again** — switch back to Rider, check **My rides** for confirmed pickup details

## Project structure

```
lib/
├── core/           # theme, router, shared widgets, constants
├── data/           # models, seed data, repository (local persistence)
└── features/
    ├── auth/       # splash, login, OTP
    ├── home/       # home screen
    ├── search/     # trip search & results
    ├── trips/      # trip details, my rides, post ride
    ├── requests/   # seat request & status
    └── profile/    # role switch, logout
```

## Tech stack

- Flutter (Material 3)
- [Riverpod](https://riverpod.dev/) — state management
- [go_router](https://pub.dev/packages/go_router) — navigation
- [shared_preferences](https://pub.dev/packages/shared_preferences) — local persistence

## Analysis

```bash
flutter analyze
```

## Out of scope (v1)

Insurance, KYC, SOS, live tracking, UPI/payments, and claim flows are intentionally excluded. The owner will add insurance after partner discussions.

## License

Private — see repository owner.
