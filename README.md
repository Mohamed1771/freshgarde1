<div align="center">

<img src="assets/images/logo.png" width="120" alt="FreshRoute AI logo"/>

# FreshRoute AI

**منصة أردنية للتجارة الزراعية والنقل المبرّد الذكي**
B2B agricultural trade + AI-assisted refrigerated transport for Jordanian traders

Flutter · Material 3 · Arabic RTL · Android · iOS · Web

</div>

---

## نظرة عامة (بالعربي)

FreshRoute AI تطبيق للتجّار الأردنيين لتصدير واستيراد الخضار والفواكه ومتابعة الشحنات المبرّدة لحظيًا.

- **السوق:** عروض تصدير واستيراد بالصور (بندورة، خيار، بطاطا).
- **إنشاء شحنة تصدير** من الأردن إلى داخل المملكة (حسب المحافظة) أو إلى الخارج (السعودية، الإمارات، قطر، الكويت، البحرين، عُمان، العراق، لبنان، مصر).
- **شحناتي:** نشطة، قيد الانتظار، تم التسليم، مؤرشفة.
- **المتابعة المباشرة:** عند فتح أي شحنة تظهر شاحنة مبرّدة ثلاثية الأبعاد، وتحتها بيانات تتغيّر مع الوقت: الحرارة، الرطوبة، نقطة الضبط، الجودة، النضج والتدهور، الحالة المتوقعة عند الوصول، توصيات التبريد، قرارات نظام التبريد الذكي، والتنبيهات.
- **سيناريوهات ثابتة ومتنوعة:** لكل شحنة سيناريو (عطل تبريد، موجة حر، تذبذب طاقة، انخفاض رطوبة…) حتى لا تكون البيانات نفسها في كل مرة، وهي جاهزة لتقييم نموذج الذكاء الاصطناعي لاحقًا.

> جميع البيانات في هذه النسخة تجريبية، والمحاكاة توضيحية وليست نموذجًا علميًا معتمدًا.

---

## Contents

1. [Features](#features)
2. [Quick start](#quick-start)
3. [Demo account](#demo-account)
4. [Demo walkthrough](#demo-walkthrough)
5. [Live simulation](#live-simulation)
6. [Architecture](#architecture)
7. [Data model](#data-model)
8. [Connecting the Three.js scene](#connecting-the-threejs-scene)
9. [Connecting the Python AI model](#connecting-the-python-ai-model)
10. [Tests](#tests)
11. [Limitations and next steps](#limitations-and-next-steps)

---

## Features

| Area | What it does |
|---|---|
| **Authentication** | Splash, login (email or Jordanian phone), 4-step trader registration (personal → business → documents → review) with Jordan-specific documents, forgot password → OTP → reset, verification-pending screen. |
| **Home** | Shortcuts for **استيراد** (import), **تصدير** (export) and **شحناتي** (my shipments), plus the marketplace offers. |
| **Marketplace (السوق)** | Two export offers (tomatoes, cucumbers) and one import offer (potatoes) with real photos and an export/import badge; offer details screen. |
| **Export shipment** | 5-step wizard: exporter (prefilled from the profile) → importer (**country**, company, contact, phone, address) → product → transport (truck, driver, origin, destination city of the chosen country, dates, cooling setpoint, documents) → review. Validation on every step. The new shipment appears in **My Shipments → Pending**. |
| **My Shipments** | Active / Pending / Delivered / Archived tabs. |
| **Live shipment view** | Embedded Three.js refrigerated truck + live panels (see [Live simulation](#live-simulation)). No simulation controls: the trip runs on its own. |
| **Notifications** | Shipment, alert and system notifications with details; at least one minute between simulation alerts. |
| **Account & settings** | Trader profile and documents; notification toggles, temperature-alert threshold, simulation speed; logout. |
| **Branding** | Theme derived from the logo (leaf green → teal → cyan → deep blue); logo used in the app, favicon and web app icons. |

---

## Quick start

Requirements: **Flutter 3.47+ (Dart 3.13+)**, Chrome for web, Android Studio / an emulator or a device for Android.

```bash
git clone <this repository>
cd freshroute_platform
flutter pub get

# Web (Chrome). Release mode is the most reliable way to run locally.
flutter run -d chrome --release

# Android (emulator or USB device)
flutter run -d android

# Build an APK
flutter build apk --release      # build/app/outputs/flutter-apk/app-release.apk

# Quality checks
flutter analyze
flutter test
```

> **Windows tip:** if `flutter` is not recognised, use the full path to `flutter.bat`
> (for example `C:\Users\<you>\dev\flutter\bin\flutter.bat run -d chrome --release`) or add `flutter\bin` to your PATH.
>
> If debug mode fails with *"Failed to establish connection with the application instance in Chrome"*,
> run with `--release` (it does not need the debug connection).

---

## Demo account

| | |
|---|---|
| Email | `ahmad@gmail.com` |
| Phone (alternative) | `0791234567` |
| Password | `12345678` |
| OTP for password reset | `123456` |

A newly registered trader lands on *verification pending*; the button there simulates the admin approval.
All accounts live in memory for the running session.

---

## Demo walkthrough

1. Sign in with the demo account.
2. **Home → استيراد** opens the marketplace: 2 export offers and 1 import offer.
3. **Home → تصدير** creates a shipment. Choose the importer country:
   * **Jordan** → destination is a governorate (Amman, Irbid, Aqaba…), Jordanian phone `07XXXXXXXX`;
   * **another country** → destination is one of its cities (e.g. UAE → Dubai), international phone `+971…`.
4. The shipment appears in **شحناتي → قيد الانتظار**. Open it: the 3D truck and the live panels appear.
5. Press **انطلاق الشاحنة** (truck departs). The trip runs by itself; readings, charts, produce state,
   AI decisions and alerts change as the scenario's events happen. On arrival the shipment becomes *Delivered*.
6. Open **FR-24017** (active, scenario *temporary cooling failure*) to see a compressor failure happen live.

---

## Live simulation

Opening a shipment shows the 3D truck (the existing Three.js scene, embedded) and panels driven by a pure-Dart,
deterministic model. `LiveSimulationService` keeps one session per shipment for the whole app session:

* **Active** shipments run continuously from their current progress (default speed 0.5 simulated hours per second,
  a 48 h trip ≈ 96 s; configurable in Settings) and are marked **Delivered** on arrival.
* **Pending** shipments wait at hour 0 until the truck departs.
* **Delivered / archived** shipments show the completed trip.

### Model (`lib/features/simulation/mock_simulation_engine.dart`)

* **Ripeness and deterioration are separate state variables.** Ripening follows a Q10 temperature law;
  deterioration grows with heat abuse, chilling, low humidity and over-ripening.
* **Cooling physics:** cargo temperature moves towards the setpoint according to cooling capacity, and towards the
  outside temperature through leakage (much faster with the door open or the unit down).
* **Decision layer (always on):** every 3 simulated hours it re-evaluates the setpoint from the produce stage,
  remaining time and cooling capacity, and logs a reason and a confidence. It raises an alert decision when it
  detects a cooling failure. *(Rule-based; a placeholder for the trained model.)*
* **Outputs:** cargo / outside temperature, humidity, setpoint, quality %, maturity stage, ripeness, deterioration,
  half-hourly history, cooling recommendations, alerts, and the predicted condition on arrival.
* **Alerts** are spaced: at least 2 simulated hours **and one real minute** apart, the same kind of alert is not
  repeated within 8 simulated hours, and critical alerts go first.

### Scenarios (`lib/shared/models/simulation_scenario.dart`)

Each shipment gets a fixed scenario picked from its ID, with event times shifted by up to ±2 h per shipment, so
trips are varied but reproducible — useful as data for evaluating the AI model and its decisions later.

| Scenario | Events |
|---|---|
| رحلة مستقرة — stable trip | short door opening at inspection |
| عطل تبريد مؤقت — temporary cooling failure | door opening; compressor failure ~26–31 h, then repaired |
| موجة حر وتأخير حدودي — heat wave + border delay | +8 °C ambient 10–30 h; idle wait at the border with a door opening |
| تذبذب طاقة الوحدة — power fluctuation | cooling capacity drops to 35 % twice |
| انخفاض الرطوبة — humidity loss | humidifier off from ~12 h |
| عطل قرب الوصول — failure near arrival | unrepaired cooling failure from ~39 h |

Scenario cooling failures are forwarded to the Three.js scene automatically.

---

## Architecture

State management: **provider** + `ChangeNotifier` repositories (in memory; changes persist for the session).
Navigation: named routes in `lib/core/routing/routes.dart`, with IDs as arguments.

```
lib/
├── main.dart
├── app/                      MaterialApp, providers, ShellController (bottom-navigation tabs)
├── core/
│   ├── routing/              named routes
│   ├── theme/                colours (from the logo), Material 3 theme, Cairo + IBM Plex Sans Arabic
│   ├── utils/                formatters and validators (Jordanian phone, plates, …)
│   └── widgets/              shared UI: cards, forms, step progress, logo, charts, produce visual
├── features/
│   ├── auth/                 splash, login, registration, forgot password / OTP / reset, pending
│   ├── dashboard/            main shell (bottom navigation) and home
│   ├── marketplace/          offers list, offer card, offer details
│   ├── export/               5-step shipment wizard
│   ├── shipments/            My Shipments, live shipment view and its panels
│   ├── simulation/           SimulationBridge, engine, live service, Three.js viewports
│   ├── notifications/        notifications list and details
│   ├── profile/              trader profile
│   └── settings/             settings
└── shared/
    ├── models/               Trader, Product, TradingOffer, Shipment, SensorReading, SimulationState,
    │                         SimulationScenario, CoolingRecommendation, InspectionResult, AppNotification
    ├── repositories/         auth, offers, shipments, notifications, settings, mock_data
    └── services/             AiInspectionService (+ mock, FastAPI), media picker

assets/
├── images/                   logo, product photos
└── sim/index.html            bundled offline Three.js truck scene

tools/fastapi_server_example.py   reference server for the AI model
test/                             unit + end-to-end UI tests
```

**Packages:** `provider`, `google_fonts` (pinned to v8 — v9 is built on the separate `material_ui` package and its
`TextTheme` does not match Flutter's), `webview_flutter`, `image_picker`, `http`, `web`.

---

## Data model

* `Shipment` — exporter, importer (company, contact, **country**), product, quantity, packaging, origin (Jordan),
  destination city, dates, truck, cooling setpoint, latest reading + history, quality, forecast, alerts, scenario.
* `TradingOffer` — export / import offer with photo, quantity, price per ton, origin, destination, partner.
* `SimulationState` — everything the live view shows at a given simulated hour.
* `InspectionResult` — typed result of a produce inspection with JSON (de)serialisation (FastAPI contract).

Sample data (`lib/shared/repositories/mock_data.dart`) uses Jordanian traders, governorates, farming areas
(Jordan Valley, Mafraq…), Jordanian truck plates and prices in JOD.

---

## Connecting the Three.js scene

The bundled scene is `assets/sim/index.html` (an offline build of the existing simulation).

* **Android / iOS:** `scene_viewport_mobile.dart` loads it in `webview_flutter` and listens on the `FR`
  JavaScript channel.
* **Web:** `scene_viewport_web.dart` loads it in an `<iframe>` platform view, installs `window.FR`, hides the page's
  own side panel and evaluates commands directly. Chosen through a conditional export (`scene_viewport.dart`),
  so web-only libraries never reach mobile builds.
* **Hosted scene:** set `SceneConfig.hostedUrl` in `scene_config.dart`. A cross-origin page on the web must accept
  `postMessage({type: 'fr-command', js})` and post snapshots with `parent.postMessage({source: 'freshroute-sim', ...}, '*')`.

`SimulationBridge` maps to `window.FreshRouteAPI`:

| Bridge | Three.js |
|---|---|
| `initializeShipment`, `reset` | `reset()`, `setSpeed()`, `setAI(true)` |
| `setProductFromAI` | `applyPrediction(0, {stage, confidence, source})` (crate 1 shows the inspected stage) |
| `start` / `pause` | `play()` / `pause()` + `seek(h)` |
| `setTime` | `seek(h)` — also every ~6 s to keep the scene clock aligned |
| scenario cooling failure | `toggleFailure()` |
| `onSimulationStateChanged` | stream of `SimulationState` |

---

## Connecting the Python AI model

The inspection screen is not part of this MVP, but the integration layer is kept in `lib/shared/services/`:

* `AiInspectionService` — interface used by the app.
* `MockAiInspectionService` — deterministic demo results, clearly marked as simulated.
* `FastApiInspectionService` — calls your model:
  * `POST /predict/image` and `POST /predict/video` (multipart field `file`, optional `product_hint`)
  * returns the JSON documented on `InspectionResult`
    (`product`, `maturity_stage` ∈ `mature_green | breaker | turning | ripe | overripe | spoiled`,
    `confidence`, `quality_score`, `defects`, `recommendation`, `model_version`, `simulated: false`).

`tools/fastapi_server_example.py` is a ready-to-edit reference server:

```bash
pip install fastapi uvicorn python-multipart
uvicorn fastapi_server_example:app --host 0.0.0.0 --port 8000
```

Apply a result with `ShipmentRepository.applyInspection` and `SimulationBridge.setProductFromAI`; the simulation
then starts from the inspected maturity stage. From the Android emulator the server is `http://10.0.2.2:8000`;
from Chrome use `http://localhost:8000` and enable CORS.

---

## Tests

```bash
flutter test
```

* `test/core_logic_test.dart` — mock AI service determinism and JSON round-trip, simulation engine
  (ripeness vs. deterioration, scenarios differ, cooling failure raises alerts), shipment flow.
* `test/login_flow_test.dart` — splash → login validation → home.
* `test/acceptance_journey_test.dart` — full journey through the real UI: login → marketplace → 5-step export to
  Dubai (UAE) → My Shipments → live view → truck departs → time passes → scenario alerts on the shipment.

---

## Limitations and next steps

* All data is mock and in memory; there is no backend yet (repositories are ready to be swapped for API clients).
* The simulation kinetics are illustrative (Q10-based), not validated science. Every trip lasts 48 simulated hours,
  including short domestic trips.
* The AI decision layer is rule-based; it is the integration point for the trained model.
* Document uploads keep only file names; no personal ID numbers are collected.
* Android allows cleartext HTTP for a local FastAPI server (`usesCleartextTraffic`); disable it for production.
