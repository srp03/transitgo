import { useEffect, useMemo, useState } from 'react';
import MapView from '../components/MapView';
import { api } from '../services/api';
import BookingFlow from '../components/BookingFlow';
import { ErrorState, LoadingState } from '../components/States';
import { createSimulatedTimetable, getSimulation, getUpcomingDepartures } from '../utils/transitSimulation';

function normalizeRouteNumber(value = '') {
  return value.trim().toUpperCase().replace(/^(BUS|ROUTE)\s*/, '').replace(/\s+/g, '');
}

function normalizeSearchText(value = '') {
  return value.trim().toLocaleLowerCase();
}

export default function Home({
  userLocation,
  popularRoutes = [],
  popularRoutesLoading = false,
  popularRoutesError = '',
  onRetryRoutes
}) {
  const [query, setQuery] = useState('');
  const [selectedRoute, setSelectedRoute] = useState(null);
  const [routeStops, setRouteStops] = useState([]);
  const [routeEndpoints, setRouteEndpoints] = useState([]);
  const [schedules, setSchedules] = useState([]);
  const [routeLoading, setRouteLoading] = useState(false);
  const [routeError, setRouteError] = useState('');
  const [clock, setClock] = useState(() => new Date());
  const [simulationAnchor, setSimulationAnchor] = useState(() => new Date());
  const [bookingOpen, setBookingOpen] = useState(false);
  const [searchRouteResults, setSearchRouteResults] = useState({ query: '', routes: [], error: '' });
  const [nearbyStopState, setNearbyStopState] = useState({ key: '', status: 'idle', stops: [], error: '' });
  const [selectedNearbyStop, setSelectedNearbyStop] = useState(null);

  const suggestions = useMemo(() => {
    const value = normalizeSearchText(query);
    if (!value) return [];
    const routeQuery = normalizeRouteNumber(query);
    const routeNumberMatches = popularRoutes.filter((route) =>
      normalizeRouteNumber(route.routeNumber || '').includes(routeQuery)
    ).sort((first, second) => {
      const firstNumber = normalizeRouteNumber(first.routeNumber || '');
      const secondNumber = normalizeRouteNumber(second.routeNumber || '');
      const firstRank = firstNumber === routeQuery ? 0 : firstNumber.startsWith(routeQuery) ? 1 : 2;
      const secondRank = secondNumber === routeQuery ? 0 : secondNumber.startsWith(routeQuery) ? 1 : 2;
      return firstRank - secondRank || firstNumber.localeCompare(secondNumber);
    });
    const routeTextMatches = popularRoutes.filter((route) =>
      `${route.routeName || ''} ${route.source || ''} ${route.destination || ''}`
        .toLocaleLowerCase().includes(value)
    );
    const byId = new Map();
    const apiMatches = searchRouteResults.query === query.trim() ? searchRouteResults.routes : [];
    [...routeNumberMatches, ...routeTextMatches, ...apiMatches].forEach((route) => {
      if (route?.id != null && !byId.has(route.id)) byId.set(route.id, route);
    });
    return [...byId.values()].slice(0, 10);
  }, [popularRoutes, query, searchRouteResults]);
  const routeSearchPending = Boolean(query.trim()) && searchRouteResults.query !== query.trim();
  const routeSearchError = searchRouteResults.query === query.trim() ? searchRouteResults.error : '';
  const nearbyRequestKey = `${userLocation?.latitude ?? ''},${userLocation?.longitude ?? ''}`;
  const nearbyStops = nearbyStopState.key === nearbyRequestKey ? nearbyStopState.stops : [];
  const nearbyStopsLoading = nearbyStopState.key !== nearbyRequestKey || nearbyStopState.status === 'loading';
  const nearbyStopsError = nearbyStopState.key === nearbyRequestKey ? nearbyStopState.error : '';

  useEffect(() => {
    const timer = window.setInterval(() => setClock(new Date()), 1000);
    return () => window.clearInterval(timer);
  }, []);

  useEffect(() => {
    const latitude = Number(userLocation?.latitude);
    const longitude = Number(userLocation?.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return undefined;
    let active = true;
    api.getNearbyStops(latitude, longitude, 3).then((stops) => {
      if (!active) return;
      const seen = new Set();
      const nearestStops = stops.filter((stop) => {
        const key = `${stop.name.trim().toLocaleLowerCase()}:${Number(stop.latitude).toFixed(4)}:${Number(stop.longitude).toFixed(4)}`;
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      });
      setNearbyStopState({ key: `${latitude},${longitude}`, status: 'loaded', stops: nearestStops.slice(0, 12), error: '' });
    }).catch((error) => {
      if (!active) return;
      console.error('Unable to load nearby GTFS bus stops:', error);
      setNearbyStopState({
        key: `${latitude},${longitude}`,
        status: 'error',
        stops: [],
        error: 'Nearby stops are temporarily unavailable.'
      });
    });
    return () => { active = false; };
  }, [userLocation?.latitude, userLocation?.longitude]);

  useEffect(() => {
    const searchText = query.trim();
    if (!searchText) return undefined;
    let active = true;
    const timer = window.setTimeout(() => {
      api.searchRoutes(searchText, '').then((routes) => {
        if (active) setSearchRouteResults({ query: searchText, routes, error: '' });
      }).catch((error) => {
        if (active) {
          console.error('Unable to search GTFS routes and stops:', error);
          setSearchRouteResults({
            query: searchText,
            routes: [],
            error: 'GTFS search is unavailable. Please check that the transit service is running.'
          });
        }
      });
    }, 220);
    return () => {
      active = false;
      window.clearTimeout(timer);
    };
  }, [query]);

  useEffect(() => {
    if (!selectedRoute?.id) return undefined;
    let active = true;
    Promise.all([
      api.getRouteStops(selectedRoute.id),
      api.getRouteSchedules(selectedRoute.id)
    ]).then(([stops, trips]) => {
      if (!active) return;
      setRouteStops(stops);
      setSchedules(trips);
      if (stops.length === 0) {
        return Promise.allSettled([
          api.searchStops(selectedRoute.source || ''),
          api.searchStops(selectedRoute.destination || '')
        ]).then((results) => {
          if (!active) return;
          const endpointStops = results.flatMap((result, index) => {
            if (result.status === 'rejected') {
              console.error(`Unable to load GTFS route ${index === 0 ? 'origin' : 'destination'} stop:`, result.reason);
              return [];
            }
            const target = [selectedRoute.source, selectedRoute.destination][index].trim().toLocaleLowerCase();
            const matches = result.value;
            const stop = matches.find((candidate) => candidate.name.trim().toLocaleLowerCase() === target) ||
              matches.find((candidate) => candidate.name.toLocaleLowerCase().includes(target) || target.includes(candidate.name.toLocaleLowerCase()));
            return stop ? [stop] : [];
          });
          setRouteEndpoints([...new Map(endpointStops.map((stop) => [stop.id, stop])).values()]);
        });
      }
      setRouteEndpoints([]);
    }).catch(() => {
      if (active) setRouteError('We couldn’t load this route’s GTFS stops and schedule. Please try again.');
    }).finally(() => {
      if (active) setRouteLoading(false);
    });
    return () => { active = false; };
  }, [selectedRoute]);

  const simulatedTimetable = useMemo(
    () => createSimulatedTimetable(routeStops, simulationAnchor),
    [routeStops, simulationAnchor]
  );
  const simulation = useMemo(
    () => simulatedTimetable.stops.length > 0
      ? getSimulation(simulatedTimetable.stops, simulatedTimetable.schedules, clock)
      : null,
    [simulatedTimetable, clock]
  );
  const upcomingDepartures = useMemo(
    () => getUpcomingDepartures(simulatedTimetable.schedules, clock).slice(0, 4),
    [simulatedTimetable, clock]
  );
  const nextDeparture = upcomingDepartures[0];
  const trackedBus = selectedRoute && simulation ? {
    busId: `route-${selectedRoute.id}`,
    routeId: selectedRoute.id,
    routeNumber: selectedRoute.routeNumber,
    source: selectedRoute.source,
    destination: selectedRoute.destination,
    transportType: 'BUS',
    ...simulation
  } : null;

  function selectRoute(route) {
    setSelectedRoute(route);
    setSimulationAnchor(new Date());
    setQuery(route.routeNumber ? `Bus ${route.routeNumber}` : route.source || '');
    setRouteStops([]);
    setRouteEndpoints([]);
    setSchedules([]);
    setRouteLoading(true);
    setRouteError('');
  }

  function clearSelectedRoute() {
    setSelectedRoute(null);
    setRouteStops([]);
    setRouteEndpoints([]);
    setSchedules([]);
    setRouteLoading(false);
    setRouteError('');
  }

  function submitSearch(event) {
    event.preventDefault();
    if (suggestions[0]) {
      selectRoute(suggestions[0]);
    }
  }

  return (
    <div className="home-workspace">
      <section className="home-map-panel" aria-label="Selected bus route map">
        <div className="home-map-heading">
          <div>
            <span className="eyebrow">THANE · PUBLIC TRANSPORT</span>
            <h1>{selectedRoute ? `Route ${selectedRoute.routeNumber}` : 'Move around with confidence'}</h1>
            <p>{selectedRoute ? `${selectedRoute.source} to ${selectedRoute.destination}` : 'Explore bus routes and scheduled journeys.'}</p>
          </div>
          <span className="simulation-label"><span /> SIMULATED</span>
        </div>
        <div className="home-map-frame">
          {routeLoading && <div className="map-state-overlay"><LoadingState message="Loading GTFS route…" /></div>}
          {routeError && <div className="map-state-overlay"><ErrorState message={routeError} onRetry={() => selectRoute({ ...selectedRoute })} /></div>}
          <MapView
            buses={trackedBus ? [trackedBus] : []}
            stops={simulatedTimetable.stops}
            routeEndpoints={routeEndpoints}
            nearbyStops={nearbyStops}
            selectedBus={trackedBus}
            focusStop={selectedNearbyStop}
            onSelectBus={() => {}}
            onSelectStop={() => {}}
            onSelectNearbyStop={setSelectedNearbyStop}
            userLocation={userLocation}
            height="100%"
          />
          {selectedRoute && routeStops.length === 0 && !routeLoading && !routeError && (
            <div className="map-empty-hint">
              {routeEndpoints.length > 0
                ? 'GTFS route endpoints shown; no trip path is available to draw.'
                : 'This GTFS route has no stop sequence or shape available to draw.'}
            </div>
          )}
        </div>
        <div className="map-footer">
          <span><i className="legend-stop" /> GTFS stop</span>
          <span><i className="legend-nearby-stop" /> Nearby stop</span>
          <span><i className="legend-route" /> Bus route</span>
          {trackedBus && <span><i className="legend-bus" /> Simulated bus</span>}
          <span className="map-provider">Map data © OpenStreetMap</span>
        </div>
      </section>

      <aside className="home-details-panel">
        <div className="home-search-block">
          <span className="eyebrow">PLAN YOUR JOURNEY</span>
          <h2>Where are you headed?</h2>
          <p>Search by bus number, route, source or destination.</p>
          <form className="route-search-form" onSubmit={submitSearch}>
            <span className="search-glyph" aria-hidden="true">⌕</span>
            <input
              aria-label="Search bus number or destination"
              placeholder="Search buses or routes..."
              value={query}
              onChange={(event) => {
                setQuery(event.target.value);
                if (selectedRoute) clearSelectedRoute();
              }}
            />
            <button type="submit" aria-label="Search routes">Search</button>
            {query.trim() && !selectedRoute && (
              <div className="route-suggestions" role="listbox">
                {suggestions.map((route) => (
                  <button type="button" key={route.id} onClick={() => selectRoute(route)} role="option">
                    <span className="suggestion-route-number">{route.routeNumber}</span>
                    <span className="suggestion-copy">
                      <strong>Bus {route.routeNumber}</strong>
                      <small>{route.source || route.stops?.[0]?.name || 'Route'} → {route.destination || route.stops?.at(-1)?.name || route.routeName}</small>
                    </span>
                    <span className="suggestion-arrow">↗</span>
                  </button>
                ))}
                {suggestions.length === 0 && (
                  <div className="suggestion-empty" role="status">
                    {popularRoutesLoading || routeSearchPending ? 'Searching GTFS routes and stops…' : routeSearchError || 'No matching buses or routes found.'}
                  </div>
                )}
              </div>
            )}
          </form>
          {popularRoutesError && !selectedRoute && <ErrorState message={popularRoutesError} onRetry={onRetryRoutes} />}
        </div>

        {selectedRoute ? (
          <div className="selected-route-content">
            <div className="selected-route-topline">
              <div>
                <span className="route-number-chip">BUS {selectedRoute.routeNumber}</span>
                <span className="direction-copy">{selectedRoute.direction || 'Scheduled service'}</span>
              </div>
              <button type="button" className="text-button" onClick={() => { clearSelectedRoute(); setQuery(''); }}>Clear</button>
            </div>
            <h3 className="selected-route-title">{selectedRoute.source}<span>→</span>{selectedRoute.destination}</h3>
            {routeLoading && <LoadingState message="Loading stops and timetable…" />}
            {routeError && <ErrorState message={routeError} onRetry={() => selectRoute({ ...selectedRoute })} />}
            {!routeLoading && !routeError && routeStops.length > 0 && (
              <>
                <div className="live-summary-card">
                  <div className="live-summary-heading">
                    <span className="live-indicator"><i /> SIMULATED LIVE</span>
                    <span className={`status-label ${simulation?.active ? 'is-active' : ''}`}>{simulation?.status}</span>
                  </div>
                  <div className="live-stop-detail">
                    <div className="live-stop-icon">↗</div>
                    <div><small>{simulation?.active ? 'NEXT STOP' : 'UPCOMING TRIP · DEPARTS'}</small><strong>{simulation?.active ? simulation.nextStopName : `${simulation?.scheduledDayOffset ? 'Tomorrow · ' : 'Today · '}${simulation?.scheduledTime}`}</strong></div>
                    <span className="live-eta">{simulation?.active ? `${simulation.etaMinutes} min` : 'Scheduled'}</span>
                  </div>
                  <div className="trip-meta"><span>Next departure</span><strong>{nextDeparture ? `Departs in ${Math.max(1, Math.ceil(nextDeparture.minutesFromNow))} mins` : simulation?.scheduledTime}</strong></div>
                </div>
                <div className="stops-list-header"><h4>Route stops</h4><span>{routeStops.length} stops</span></div>
                <div className="home-stops-list">
                  {simulatedTimetable.stops.slice(0, 6).map((stop, index) => (
                    <div className={`home-stop-row ${simulation?.active && stop.name === simulation.currentStopName ? 'current' : ''}`} key={stop.id || index}>
                      <span className={`home-stop-dot ${index === 0 ? 'start' : index === routeStops.length - 1 ? 'end' : ''}`} />
                      <span className="home-stop-name">{stop.name}</span>
                      <span className="home-stop-time">{stop.simulatedTimeLabel}</span>
                    </div>
                  ))}
                  {routeStops.length > 6 && <div className="more-stops">+ {routeStops.length - 6} more stops on this route</div>}
                </div>
                {upcomingDepartures.length > 0 && (
                  <div className="gtfs-departures">
                    <div className="stops-list-header"><h4>Simulated departures</h4><span>DEMO</span></div>
                    <div className="departure-chips">
                      {upcomingDepartures.map(({ schedule, dayOffset }) => (
                        <span key={schedule.id}>{dayOffset ? 'Tomorrow · ' : 'Today · '}{schedule.departureTime}</span>
                      ))}
                    </div>
                  </div>
                )}
                <button type="button" className="book-ticket-button" onClick={() => setBookingOpen(true)}>Book a ticket <span>→</span></button>
              </>
            )}
            {!routeLoading && !routeError && routeStops.length === 0 && (
              <div className="route-data-empty">
                {routeEndpoints.length > 0 && (
                  <div className="endpoint-summary">
                    <strong>GTFS route endpoints</strong>
                    {routeEndpoints.map((stop) => <span key={stop.id}>{stop.name}</span>)}
                  </div>
                )}
                {schedules.length > 0
                  ? `No GTFS stop sequence is available for this route. ${schedules.length} scheduled departures were found.`
                  : 'GTFS includes this route, but no trips or route stop sequence are available to show.'}
              </div>
            )}
          </div>
        ) : (
          <div className="home-suggestions-block">
            {selectedNearbyStop && (
              <div className="nearby-selected-stop">
                <div><span className="eyebrow">SELECTED NEARBY STOP</span><strong>{selectedNearbyStop.name}</strong><small>{selectedNearbyStop.distanceKm?.toFixed?.(2)} km away</small></div>
                <button type="button" className="text-button" onClick={() => setSelectedNearbyStop(null)}>Clear</button>
              </div>
            )}
            <div className="nearby-stops-section">
              <div className="suggestions-heading"><h3>Nearby bus stops</h3><span>{nearbyStops.length ? `${nearbyStops.length} nearby` : 'Within 3 km'}</span></div>
              {nearbyStopsLoading && <LoadingState message="Finding nearby GTFS stops…" />}
              {nearbyStopsError && <p className="nearby-stops-error">{nearbyStopsError}</p>}
              {!nearbyStopsLoading && !nearbyStopsError && nearbyStops.length === 0 && (
                <p className="nearby-stops-empty">No GTFS bus stops were returned for this map area.</p>
              )}
              {nearbyStops.map((stop) => (
                <button
                  type="button"
                  key={stop.id}
                  className={`nearby-stop-row ${selectedNearbyStop?.id === stop.id ? 'active' : ''}`}
                  onClick={() => {
                    setSelectedNearbyStop(stop);
                  }}
                >
                  <span className="nearby-stop-row-icon">⌖</span>
                  <span className="nearby-stop-row-copy"><strong>{stop.name}</strong><small>{Number(stop.distanceKm || 0).toFixed(2)} km away</small></span>
                  <span className="suggestion-arrow">↗</span>
                </button>
              ))}
            </div>
            <div className="suggestions-heading"><h3>Popular routes</h3><span>{popularRoutes.length} routes</span></div>
            {popularRoutes.slice(0, 5).map((route) => (
              <button className="popular-route-row" key={route.id} onClick={() => selectRoute(route)}>
                <span className="popular-route-number">{route.routeNumber}</span>
                <span className="popular-route-copy"><strong>{route.source} → {route.destination}</strong><small>{route.direction || `${route.stopsCount || 0} stops`}</small></span>
                <span className="suggestion-arrow">↗</span>
              </button>
            ))}
            {popularRoutesLoading && <LoadingState message="Loading routes from GTFS…" />}
            {popularRoutesError && <ErrorState message={popularRoutesError} onRetry={onRetryRoutes} />}
            {!popularRoutesLoading && !popularRoutesError && popularRoutes.length === 0 && <p className="route-data-empty">No routes are currently available.</p>}
          </div>
        )}
        <div className="simulation-note"><span>ⓘ</span> Bus times and movement are demo estimates based on GTFS stops, not published departures or real-time GPS.</div>
      </aside>
      {bookingOpen && selectedRoute && (
        <BookingFlow
          route={selectedRoute}
          stops={routeStops}
          onClose={() => setBookingOpen(false)}
        />
      )}
    </div>
  );
}
