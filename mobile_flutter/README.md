# TransitGo Mobile — Flutter Android App for TMT Buses

TransitGo is a modern, production-grade Flutter Android mobile application designed for discovering Thane Municipal Transport (TMT) bus routes, navigating nearby bus stops, exploring timetable schedules, tracking bus movements, and booking digital travel passes.

---

## 1. Architecture & Tech Stack

The application adheres to clean architecture principles with distinct data, provider (state management), and presentation layers:

- **Framework:** Flutter 3.47+ / Dart 3.13+ (Null-safe)
- **UI & Design System:** Custom Material 3 system with deep navy primary (`#0D2040`), transit gold/amber accent (`#F59E0B`), and cyan teal (`#0E7490`).
- **State Management:** Riverpod 3 (`flutter_riverpod`) with `NotifierProvider` and `FutureProvider`.
- **Navigation:** `go_router` with `StatefulShellRoute` for persistent bottom navigation bar.
- **Networking:** `dio` HTTP client with timeout controls, request interceptors, and typed exception mapping.
- **Maps:** `flutter_map` with `latlong2` rendering OpenStreetMap tiles, stop pins, route polylines, and bus markers.
- **Location:** `geolocator` with runtime permission handling and fallback to Thane Station (`19.1860, 72.9759`).
- **Local Persistence:** `shared_preferences` for favourite routes, recent journeys, theme, and API server override.
- **Digital Tickets:** `qr_flutter` generating verifiable digital QR passes.

---

## 2. Project Directory Structure

```text
mobile_flutter/
├── android/                  # Android native project, permissions & cleartext network config
├── lib/
│   ├── main.dart             # App entrypoint & ProviderScope
│   ├── core/
│   │   ├── config/           # AppConfig (dynamic API host, OSM tile URL, coordinates)
│   │   ├── constants/        # AppColors (curated Material 3 light/dark tokens)
│   │   ├── network/          # ApiClient & custom ApiExceptions
│   │   ├── router/           # AppRouter (GoRouter configuration with shell navigation)
│   │   ├── storage/          # PreferencesService (SharedPreferences wrapper)
│   │   └── theme/            # AppTheme (Material 3 ThemeData for light and dark)
│   ├── data/
│   │   ├── models/           # RouteModel, StopModel, BusLocationModel, ScheduleModel, BookingModel
│   │   └── repositories/     # RouteRepository, StopRepository, BusRepository, BookingRepository
│   ├── providers/            # Riverpod providers for routes, stops, buses, bookings, location
│   └── presentation/
│       ├── screens/
│       │   ├── splash/       # Animated TransitGo splash & onboarding
│       │   ├── shell/        # Bottom navigation shell (Home, Planner, Nearby, Tickets, Profile)
│       │   ├── home/         # Journey search, quick actions, saved routes, nearby carousel
│       │   ├── planner/      # Journey planner with origin-destination stop discovery
│       │   ├── routes/       # Complete 436 TMT routes directory with direction filters
│       │   ├── route_detail/ # Interactive OSM map, ordered stop timeline, schedules & tracking
│       │   ├── nearby/       # Full interactive OSM map with distance-sorted stops
│       │   ├── tracking/     # Live bus telemetry with prominent simulated badge
│       │   ├── booking/      # Multi-step booking flow, fare calculation, mock UPI payment
│       │   ├── tickets/      # Ticket history with PostgreSQL synchronization
│       │   ├── profile/      # User profile, in-app API host switcher, dataset report
│       │   └── notices/      # Verified TMT service notices & control room helplines
│       └── widgets/          # OsmMapWidget, RouteCard, StopCard, BusLiveCard, SimulatedBadge
└── test/                     # Unit tests for models and widget component tests
```

---

## 3. Network Configuration & Backend Connection

Never hardcode localhost in mobile applications. The mobile app supports three distinct networking environments:

### A. Android Emulator
The Android emulator runs inside a virtual router where `10.0.2.2` maps to the host development computer:
```bash
flutter run --dart-define=API_URL=http://10.0.2.2:8080/api
```

### B. Physical Android Phone (Over Wi-Fi)
1. Ensure your computer and phone are connected to the same Wi-Fi network.
2. Find your computer's local LAN IP (e.g., `192.168.1.15`).
3. Launch with your LAN IP:
   ```bash
   flutter run --dart-define=API_URL=http://192.168.1.15:8080/api
   ```
4. **In-App Switcher:** You can also change the API Host at any time inside the app by opening **Profile → Network & Server Settings → Backend API Host** and tapping **Save & Apply**!

### C. Web / Desktop Preview
```bash
flutter run -d chrome
```

---

## 4. How to Run the Complete Stack

### Step 1: Start PostgreSQL and Spring Boot Backend
Ensure PostgreSQL is running, then start the backend:
```powershell
cd d:\public\backend
.\gradlew.bat bootRun
```
The API is available at `http://localhost:8080/api`.

### Step 2: Run Flutter Tests & Static Analysis
```powershell
cd d:\public\mobile_flutter
flutter test
flutter analyze
```

### Step 3: Launch Flutter App
```powershell
cd d:\public\mobile_flutter

# On Android Emulator
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:8080/api

# On Physical Android Device connected via USB / Wi-Fi
flutter run -d <device-id> --dart-define=API_URL=http://<YOUR-LAN-IP>:8080/api

# On Chrome for quick browser verification
flutter run -d chrome --dart-define=API_URL=http://localhost:8080/api
```

### Step 4: Build Release Android APK
Once the Android SDK is configured in Android Studio:
```powershell
cd d:\public\mobile_flutter
flutter build apk --release --dart-define=API_URL=https://your-production-domain.com/api
```
The resulting APK is generated at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 5. Data & Simulation Disclaimers

1. **Simulated Telemetry:** Bus locations and ETAs are generated using timetable schedules via the backend mock GPS engine. They are prominently identified with `SIMULATED DEMO` badges and modal explanations.
2. **Demo Ticketing:** Digital tickets generate unique references (`TG...`) and QR codes stored in PostgreSQL. Fares are calculated based on stop span approximation (₹10 min + ₹5/stop span). Payment is a simulated UPI interface and is not linked to real banking gateways.
3. **Route Geometry:** Route paths connect verified GTFS stop coordinates because the official TMT GTFS feed does not contain curved road shape files (`shapes.txt`).
