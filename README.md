# suzuki-store-lab

**Suzuki Moto** — a Flutter e-commerce app for Suzuki motorcycles in Thailand: browse the lineup,
finance a bike, book a test ride and find showrooms on a map. Runs on Android and in Chrome.

## Features

- Onboarding, email/password and Google sign-in (Firebase Authentication)
- Catalog of 13 Thai-market Suzuki models with Bangkok prices, colors and specs
- Live Suzuki 2026 lineup from the NHTSA API, photos from Wikimedia Commons,
  full technical specs from API Ninjas
- Cart, checkout with a finance calculator, orders and test-ride bookings (Cloud Firestore)
- Showroom & service map on OpenStreetMap with "near me" distances and directions

## Requirements

Tested with:

| Tool | Version |
|---|---|
| Flutter | 3.44.6 (stable) |
| Dart | 3.12.2 |
| Android | Emulator "Medium Phone", API 36 (Google Play image) |
| Web | Google Chrome |

Android Studio (for the Android SDK and emulator) and Chrome must be installed.
Check your setup with `flutter doctor`.

## Run it

```bash
git clone https://github.com/freddycleann/suzuki-store-lab.git
cd suzuki-store-lab
flutter pub get

flutter run              # Android emulator or device
flutter run -d chrome    # Web
```

No extra setup is needed: the Firebase configuration, API key and debug signing key are
already in the project.

## What is already configured

| Item | Where |
|---|---|
| Firebase project `lab123124` (Android app `suzuki.store`, web app `suzuki-store`) | `lib/firebase_options.dart` |
| Firestore security rules (each user reads/writes only `users/{uid}/…`) | `firestore.rules` |
| API Ninjas key for full specs | `lib/config/app_config.dart` — override with `--dart-define=API_NINJAS_KEY=…` |
| Google sign-in web client ID | `lib/config/app_config.dart` |
| Shared Android debug keystore | `android/app/debug.keystore` |
| OpenStreetMap dealer snapshot (offline fallback) | `assets/data/osm_suzuki_th.json` |

### Google sign-in

- **Android:** the app is signed with the shared debug keystore, SHA-1
  `C0:70:DD:A4:03:B5:8E:90:0F:86:46:80:71:8E:48:AB:76:46:1D:26`. This fingerprint must be added to
  the Android app `suzuki.store` in Firebase (Project settings → Your apps), and the device
  needs a Google account.
- **Web:** uses Firebase's Google popup. It works on `localhost`; for other hosts add the domain
  under Authentication → Settings → Authorized domains.

## Project structure

```
lib/
  config/      app configuration (API keys, client IDs)
  data/        Thai catalog and showroom list
  models/      motorcycle, cart, order, test ride, dealer
  services/    Firebase + demo auth/store, NHTSA, Wikimedia, API Ninjas, OpenStreetMap
  state/       session, catalog, locations, preferences
  screens/     onboarding, auth, home, explore, detail, cart, checkout, map, …
  widgets/     shared UI components
```

## Troubleshooting

- **Google sign-in on Android says "didn't finish" or "SHA-1 fingerprint isn't registered":**
  Google Play services answers with `[16] Account reauth failed` and Firebase with
  `INVALID_CERT_HASH` until the debug SHA-1 above is added to the Android app `suzuki.store` in
  Firebase → Project settings. After adding it, wait a few minutes and try again — no rebuild needed.

- **Map shows "Live update unavailable":** the public OpenStreetMap Overpass servers are often
  busy. The app then uses the bundled snapshot; tap Retry later.
- **"Near me" on the emulator:** set a location in the emulator's Extended controls → Location.
- **Demo mode:** if Firebase values in `lib/firebase_options.dart` start with `PASTE_`, the app
  runs with in-memory sign-in and data.

## Data & credits

Map data © OpenStreetMap contributors (ODbL). Motorcycle photos from Wikimedia Commons.
Lineup data from NHTSA vPIC. Specs from API Ninjas. Thai prices compiled from 9carthai.com and
ZigWheels Thailand (September 2026). Colors, showrooms and finance rates are sample data.
Lab project — not affiliated with Suzuki Motor Corporation.
