import { useState, useEffect, useMemo } from 'react';
import MapView from '../components/MapView';
import BusCard from '../components/BusCard';
import { useLiveBuses } from '../hooks/useBusTracking';
import { api } from '../services/api';
import { LoadingState } from '../components/States';
import { createSimulatedTimetable, getSimulation } from '../utils/transitSimulation';

export default function LiveTracking({
  selectedRoute = null,
  selectedBus = null,
  onViewBusDetails,
  userLocation
}) {
  const { buses, loading, error } = useLiveBuses(3000);
  const [activeBus, setActiveBus] = useState(selectedBus);
  const [routeStops, setRouteStops] = useState([]);
  const [filterRouteId, setFilterRouteId] = useState(selectedRoute?.id || null);
  const [availableRoutes, setAvailableRoutes] = useState([]);
  const [clock, setClock] = useState(() => new Date());
  const [simulationAnchor, setSimulationAnchor] = useState(() => new Date());

  useEffect(() => {
    const timer = window.setInterval(() => setClock(new Date()), 1000);
    return () => window.clearInterval(timer);
  }, []);

  // Load all routes for the filter dropdown
  useEffect(() => {
    async function loadRoutes() {
      try {
        const data = await api.getAllRoutes();
        setAvailableRoutes(data);
      } catch (err) {
        console.error('Error loading routes for filter:', err);
      }
    }
    loadRoutes();
  }, []);

  // Sync selected bus from props
  useEffect(() => {
    if (selectedBus) {
      setActiveBus(selectedBus);
      setFilterRouteId(selectedBus.routeId);
      setSimulationAnchor(new Date());
    }
  }, [selectedBus]);

  // Sync selected route from props
  useEffect(() => {
    if (selectedRoute && selectedRoute.id) {
      setFilterRouteId(selectedRoute.id);
      setSimulationAnchor(new Date());
    }
  }, [selectedRoute]);

  // Fetch stops for active route filter
  useEffect(() => {
    if (!filterRouteId) {
      setRouteStops([]);
      return;
    }
    let isMounted = true;
    async function loadStops() {
      try {
        const stops = await api.getRouteStops(filterRouteId);
        if (isMounted) setRouteStops(stops);
      } catch (err) {
        console.error('Error fetching stops for route:', err);
      }
    }
    loadStops();
    return () => { isMounted = false; };
  }, [filterRouteId]);

  // Filter visible buses on map
  const visibleBuses = buses.filter((b) => {
    if (!filterRouteId) return true;
    return b.routeId === filterRouteId;
  });

  const activeFilterRoute = availableRoutes.find(r => r.id === filterRouteId);
  const simulatedTimetable = useMemo(
    () => createSimulatedTimetable(routeStops, simulationAnchor),
    [routeStops, simulationAnchor]
  );
  const simulatedPosition = useMemo(
    () => simulatedTimetable.stops.length > 0
      ? getSimulation(simulatedTimetable.stops, simulatedTimetable.schedules, clock)
      : null,
    [simulatedTimetable, clock]
  );
  const simulatedBus = filterRouteId && activeFilterRoute && simulatedPosition ? {
    busId: `route-${filterRouteId}`,
    routeId: filterRouteId,
    routeNumber: activeFilterRoute.routeNumber,
    source: activeFilterRoute.source,
    destination: activeFilterRoute.destination,
    transportType: 'BUS',
    isMock: true,
    dataLabel: 'Schedule simulation',
    ...simulatedPosition
  } : null;
  const routeBus = visibleBuses.length > 0 ? visibleBuses : simulatedBus ? [simulatedBus] : [];
  const selectedMapBus = activeBus && activeBus.busId === simulatedBus?.busId
    ? simulatedBus
    : activeBus;

  return (
    <div className="live-tracking-page">
      {/* Top Filter Header Bar */}
      <div className="tracking-top-bar">
        <div className="tracking-title-group">
          <span className="live-pulsing-icon">📡</span>
          <div>
            <h2>Live Bus Tracking</h2>
            <p className="subtitle">
              {error
                ? simulatedBus ? 'GPS service unavailable • route simulation shown' : 'GPS service unavailable'
                : 'Simulated GPS • Updates every 3s'}
              {' '}<span className="demo-tag">DEMO</span>
            </p>
          </div>
        </div>

        {/* Route Filter Dropdown - populated from API */}
        <div className="route-filter-select">
          <label>Filter Route:</label>
          <select
            value={filterRouteId || ''}
            onChange={(e) => {
              const val = e.target.value ? Number(e.target.value) : null;
              setFilterRouteId(val);
              setActiveBus(null);
              setSimulationAnchor(new Date());
            }}
          >
            <option value="">All Active Routes ({buses.length} buses)</option>
            {availableRoutes.map((route) => (
              <option key={route.id} value={route.id}>
                {route.routeNumber} — {route.source} → {route.destination}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Active Route Info Strip */}
      {activeFilterRoute && (
        <div className="active-route-strip">
          <span className="route-badge-strip">🚌 {activeFilterRoute.routeNumber}</span>
          <span className="route-path-strip">{activeFilterRoute.source} → {activeFilterRoute.destination}</span>
          <span className="stops-info-strip">{activeFilterRoute.stopsCount} stops</span>
        </div>
      )}

      {/* Main Full-Screen / Large Map Container */}
      <div className="tracking-map-wrapper">
        {loading && <div className="map-loading-overlay"><LoadingState message="Connecting to GPS engine..." /></div>}

        <MapView
          buses={routeBus}
          stops={simulatedTimetable.stops}
          selectedBus={selectedMapBus}
          onSelectBus={(bus) => setActiveBus(bus)}
          userLocation={userLocation}
          height="calc(100vh - 220px)"
        />

        {/* Floating Bus Info Card Overlay */}
        {selectedMapBus && (
          <div className="floating-bus-overlay">
            <BusCard
              bus={selectedMapBus}
              onViewBusDetails={onViewBusDetails}
              onClose={() => setActiveBus(null)}
            />
          </div>
        )}
      </div>
    </div>
  );
}
