# TransitGo

TransitGo is a public-transport route discovery and ticket-booking prototype for the Thane area. It combines a React map-based interface with a Kotlin/Spring Boot API and route, stop, trip, and timetable data imported from the GTFS files in `database/`.

This project is intended as a demonstration: bus positions are simulated, and ticket payment is not connected to a real payment provider.

## Project workflow

1. **Load transit data:** On backend startup, the application looks for the GTFS files in `database/` and imports the supported TMT routes, stops, trips, and stop-time information into PostgreSQL. The importer checks for existing TMT routes to avoid importing the same data again.
2. **Find a journey:** On Home, search by route number (for example, `54`), route/source/destination, or a stop name. Suggestions are based on routes returned by the backend. Selecting a suggestion keeps the user on Home.
3. **Explore the map:** The existing Leaflet map displays available route stops and nearby stops. Nearby stops use the browser's location when available; otherwise, the app uses a default location near Thane Station. A route line is drawn from available GTFS stop coordinates. The supplied feed does not include `shapes.txt`, and routes without a trip stop sequence cannot show an invented path.
4. **Check service information:** Route details include available stops and schedule information. The Home map's **SIMULATED LIVE** marker estimates movement from the selected route's stop times and the current browser time. It is a visualization only and does not use live GPS.
5. **Create a demo ticket:** Choose a boarding stop, a later destination stop, travel date/time, and passenger count. Review the estimated fare and ticket details, then use the mock UPI payment screen. A successful demo payment generates a booking reference and ticket.
6. **Review bookings:** Demo bookings are saved in the current browser's local storage and appear in Profile under booking history. They are not sent to the backend and are not shared across browsers or devices.

## Main functionality

- Search GTFS-backed routes by route number, route name, source/destination, and stop name.
- See route details, available stops, schedules, and nearby stops.
- View available GTFS stop coordinates and schedule-based simulated bus movement on the map.
- Complete a frontend-only ticket selection, review, mock payment, and ticket confirmation flow.
- View locally stored demo bookings and profile settings.
- Browse route, bus, stop, and timetable views supported by the existing application.

## Technology

| Area | Technology |
| --- | --- |
| Frontend | React 19, Vite, JavaScript |
| Map | Leaflet with OpenStreetMap map tiles |
| Backend | Kotlin, Spring Boot, Spring Data JPA |
| Database | PostgreSQL |
| Transit source data | GTFS text files in `database/` |

## Repository layout

```text
.
├── database/                 # GTFS source files
├── frontend/                 # React/Vite application
│   └── src/
│       ├── components/       # Map, booking, navigation, and shared UI
│       ├── pages/            # Home, routes, tracking, profile, and other views
│       └── services/api.js   # Frontend API client
└── backend/                  # Kotlin/Spring Boot API
    └── src/main/kotlin/      # Controllers, services, entities, and GTFS importer
```

## Requirements

- Node.js and npm
- Java 17 or newer
- PostgreSQL
- The GTFS files in `database/` (the importer requires `routes.txt`, `stops.txt`, `trips.txt`, and `stop_times.txt`)

## Run locally on Windows

### 1. Configure PostgreSQL

Create a PostgreSQL database named `transitgo`, then configure the connection URL, username, and password for the backend in:

```text
backend/src/main/resources/application.properties
```

Keep local credentials private; do not commit passwords or other secrets.

**Database warning:** The current backend configuration uses Hibernate's `create` schema mode. Starting the backend recreates the application schema, so use a disposable development database and do not point it at data you need to preserve.

### 2. Start the backend

From the repository root, run:

```powershell
cd backend
.\gradlew.bat bootRun
```

The API runs on `http://localhost:8080` by default. On startup, the importer searches for the project GTFS directory and loads supported TMT data if it has not already been imported.

### 3. Start the frontend

Open another PowerShell window at the repository root:

```powershell
cd frontend
npm install
npm run dev
```

Open the local URL printed by Vite (normally `http://localhost:5173`). The frontend uses `http://localhost:8080/api` by default. To use a different API base URL, set `VITE_API_BASE_URL` in the frontend environment before starting or building the app.

### 4. Build and test

Frontend production build:

```powershell
cd frontend
npm run build
```

Frontend lint:

```powershell
npm run lint
```

Backend tests:

```powershell
cd backend
.\gradlew.bat test
```

## API overview

The frontend currently calls the following backend resources:

| Resource | Purpose |
| --- | --- |
| `GET /api/routes` | List available TMT routes |
| `GET /api/routes/{id}` | Get route details |
| `GET /api/routes/{id}/stops` | Get the available ordered stop sequence |
| `GET /api/routes/{id}/schedule` | Get route departure times |
| `GET /api/routes/{id}/buses` | Get buses associated with a route |
| `GET /api/routes/search?from=...&to=...` | Search routes by route number, stop, or journey text |
| `GET /api/stops` | List stops |
| `GET /api/stops/nearby?lat=...&lng=...&radius=...` | Find stops near a coordinate |
| `GET /api/stops/search?query=...` | Search stop names |
| `GET /api/buses` | List buses |
| `GET /api/buses/live` | Get available simulated bus locations |

The booking and mock-payment flow is currently frontend-only; it does not create a server-side booking or charge a payment method.

## Data and demonstration limitations

- The importer currently focuses on TMT records from the supplied GTFS files.
- Available route paths depend on GTFS trip stop sequences and stop coordinates. The dataset does not include a `shapes.txt` file, so the application does not claim to display an official GTFS shape.
- Some route records may not have trips or stop sequences in the supplied feed. In that case, schedules or intermediate stops may be unavailable; the UI can show endpoint information where available rather than fabricate a path.
- The Home-page bus marker is a **schedule-based simulation**, not a real-time vehicle location.
- The mock UPI screen does not contact a bank or payment gateway. Its fare is an estimate, and its ticket/booking reference is for demonstration only.
- Profile bookings are stored in browser local storage. The profile and booking history are not backed by user authentication or a booking API.

