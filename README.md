# FreshRoute AI — Flutter app (demo)

B2B agricultural import/export and AI-assisted refrigerated transport for Jordanian traders.
Arabic RTL, Material 3, runs on **Android, iOS and Chrome** with no backend: all data is in-memory mock data
that persists for the running session.

> Everything that is not real is labelled in the UI ("بيانات تجريبية", "نتيجة محاكاة", "مظهر محاكى").
> The mock AI service never pretends to run a model.

## Run

Requires Flutter 3.47+ (Dart 3.13). The SDK on this machine is at `C:\Users\user\dev\flutter`.

```bash
flutter pub get
flutter run -d chrome          # web
flutter run -d android         # emulator or device (flutter devices to list)
flutter build apk --release    # build/app/outputs/flutter-apk/app-release.apk
flutter analyze && flutter test
```

### Demo credentials

| | |
|---|---|
| Email | `demo@freshroute.jo` (or phone `0791234567`) |
| Password | `Demo1234` |
| OTP (forgot password) | `123456` |

The login screen has a "تعبئة البيانات التجريبية" button. A newly registered trader lands on
"verification pending"; the button there simulates the admin approval.

## App scope (MVP)

* **Home** — import / export / my shipments shortcuts, critical-alert banner, and the marketplace offers.
* **Marketplace (السوق)** — three offers with photos: tomatoes and cucumbers (export), potatoes (import).
* **Export** — 5-step shipment wizard; the new shipment appears in My Shipments → Pending.
* **My Shipments** — Active / Pending / Delivered / Archived; opening one shows the live 3D simulation.
* **Account** — profile, settings (notifications, alert threshold, simulation speed), logout.

Deals, reports, the side menu and the AI inspection screen were removed for the MVP. The inspection
service layer (`AiInspectionService`, `FastApiInspectionService`) is kept in `lib/shared/services/` for
connecting the Python model later.

## Demo journey (covered by `test/acceptance_journey_test.dart`)

Login → Home → **استيراد** (marketplace: 2 export + 1 import offers) → **تصدير** (5-step wizard)
→ My Shipments (Pending) → open the shipment (live view) → **انطلاق الشاحنة** → the trip runs on its own:
readings, charts, produce, forecast, decisions and alerts update as the scenario's events happen.

## Live simulation and scenarios

Opening any shipment shows its live view: the 3D truck on top and live panels below. There are no simulation
controls. `LiveSimulationService` keeps one session per shipment for the app session:

* **active** shipments run continuously (speed in Settings, default 0.5 simulated h/s → a 48 h trip in ~96 s),
  starting from their current progress, and are marked **delivered** on arrival;
* **pending** shipments wait at hour 0 until "انطلاق الشاحنة";
* **delivered / archived** shipments show the completed trip.

Each shipment has a fixed `SimulationScenario` (`lib/shared/models/simulation_scenario.dart`), picked from its ID,
with event times shifted by up to ±2 h per shipment:

| Scenario | Events |
|---|---|
| رحلة مستقرة | short door opening at customs |
| عطل تبريد مؤقت | door opening, compressor failure ~26–31 h then repaired |
| موجة حر وتأخير حدودي | +8 °C ambient 10–30 h, idle border wait with door opening |
| تذبذب طاقة الوحدة | cooling capacity drops to 35% twice |
| انخفاض الرطوبة | humidifier off from ~12 h |
| عطل قرب الوصول | unrepaired cooling failure from ~39 h |

Scenario cooling failures are forwarded to the Three.js scene automatically. Every hour of the simulated
trip (telemetry, events, decisions) is available in `SimulationState`, which makes it a ready data source
for evaluating a future model and its decisions.

## Architecture

```
lib/
  main.dart, app/            MaterialApp, providers, ShellController (bottom-nav tab switching)
  core/theme, routing, widgets, utils
  features/
    auth/                    splash, login, 4-step registration, forgot/OTP/reset, pending
    dashboard/               MainShell (bottom nav + drawer), home
    marketplace/             offers, offer details, deal request
    export/                  5-step shipment wizard
    shipments/               My Shipments tabs, shipment details
    ai_inspection/           pick image/video → analyze → apply
    simulation/              SimulationBridge, MockSimulationEngine/Bridge, scene/ viewports
    notifications/ deals/ reports/ profile/ settings/
  shared/
    models/                  Trader, Product, TradingOffer, Shipment, InspectionResult,
                             SensorReading, SimulationState, CoolingRecommendation, …
    repositories/            in-memory ChangeNotifier repositories + mock_data.dart
    services/                AiInspectionService (+ Mock, FastAPI), MediaPicker
```

State management: **provider** + `ChangeNotifier` repositories. Navigation: named routes (`core/routing/routes.dart`)
with IDs as arguments, so screens always read fresh data.

Packages: provider, google_fonts (Cairo / IBM Plex Sans Arabic, pinned to v8 because v9 is built on the separate
`material_ui` package), webview_flutter, image_picker, http, web.

## Connecting your Python AI model

The inspection screen is not part of the MVP. To bring it back, call `AiInspectionService` (mock or
`FastApiInspectionService`) and apply the result with `ShipmentRepository.applyInspection` and
`SimulationBridge.setProductFromAI`. The FastAPI contract (`POST /predict/image`, `POST /predict/video`)
is documented on `InspectionResult`; `tools/fastapi_server_example.py` is a reference server.

## Connecting the Three.js simulation

The bundled scene is `assets/sim/index.html`, copied from `freshroute_app/assets/sim` (your existing build;
rebuild it there with `cd sim_src && npm install && node build.mjs ../assets/sim` and copy it over).

* **Android / iOS** — `scene_viewport_mobile.dart` loads it in `webview_flutter` and registers the `FR`
  JavaScript channel the scene already uses.
* **Web** — `scene_viewport_web.dart` loads it in an `<iframe>` platform view, installs `window.FR` inside it and
  evaluates commands directly (same origin). Selected through a conditional export in `scene_viewport.dart`,
  so web-only libraries never reach mobile builds.
* **Hosted scene** — set `SceneConfig.hostedUrl` (`lib/features/simulation/scene/scene_config.dart`).
  For a cross-origin page on the web, add this to the scene:

  ```js
  window.addEventListener('message', e => { if (e.data?.type === 'fr-command') eval(e.data.js); });
  // and post snapshots back with: parent.postMessage({source: 'freshroute-sim', ...snapshot}, '*')
  ```

`SimulationBridge` (`lib/features/simulation/simulation_bridge.dart`) maps the commands to `window.FreshRouteAPI`:

| Bridge | Three.js |
|---|---|
| `initializeShipment`, `reset` | `reset()`, `setSpeed()` |
| `setProductFromAI` | `applyPrediction(0, {stage, confidence, source})` — crate 1 shows the inspected stage |
| `start` / `pause` | `play()` / `pause()` + `seek(h)` to resync |
| `setTime` | `seek(h)` (also every ~6 s to keep the scene clock aligned) |
| scenario cooling failure (automatic) | `toggleFailure()` |
| `onSimulationStateChanged` | stream of `SimulationState`; scene `snapshot` messages are shown in the viewport |

The Flutter panels are driven by `MockSimulationEngine` (pure Dart, deterministic, illustrative Q10 kinetics with
**separate ripeness and deterioration** variables and a rule-based setpoint decision layer). It keeps the demo working
where no scene is attached (tests, unsupported platforms). To make the scene the source of truth instead, implement
`SimulationBridge` by parsing the scene's `snapshot` messages into `SimulationState`.

## Notes

* Document uploads keep only the file name — no file contents and no personal ID numbers are stored or logged.
* Android: `usesCleartextTraffic="true"` is enabled for a local `http://` FastAPI server; turn it off for production.
* Fonts are fetched by google_fonts at runtime; offline, the platform Arabic font is used.
