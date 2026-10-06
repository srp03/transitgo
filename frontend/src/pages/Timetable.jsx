import { useState, useEffect } from 'react';
import { api } from '../services/api';
import { LoadingState, ErrorState } from '../components/States';

export default function Timetable({ onSelectRoute, onTrackBus }) {
  const [routes, setRoutes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedRouteId, setSelectedRouteId] = useState(null);
  const [schedules, setSchedules] = useState([]);
  const [schedulesLoading, setSchedulesLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    let isMounted = true;
    async function loadData() {
      setLoading(true);
      setError(null);
      try {
        const data = await api.getAllRoutes();
        if (isMounted) {
          setRoutes(data);
          if (data.length > 0) setSelectedRouteId(data[0].id);
        }
      } catch (err) {
        if (isMounted) setError('Failed to load TMT route timetables');
      } finally {
        if (isMounted) setLoading(false);
      }
    }
    loadData();
    return () => { isMounted = false; };
  }, []);

  useEffect(() => {
    if (!selectedRouteId) return;
    let isMounted = true;
    async function loadSchedules() {
      setSchedulesLoading(true);
      try {
        const data = await api.getRouteSchedules(selectedRouteId);
        if (isMounted) setSchedules(data);
      } catch (err) {
        console.error('Error loading schedule:', err);
        if (isMounted) setSchedules([]);
      } finally {
        if (isMounted) setSchedulesLoading(false);
      }
    }
    loadSchedules();
    return () => { isMounted = false; };
  }, [selectedRouteId]);

  const filteredRoutes = routes.filter((r) => {
    if (!searchQuery) return true;
    const q = searchQuery.toLowerCase();
    return r.routeNumber?.toLowerCase().includes(q) ||
      r.source?.toLowerCase().includes(q) ||
      r.destination?.toLowerCase().includes(q) ||
      r.routeName?.toLowerCase().includes(q);
  });

  const activeRoute = routes.find((r) => r.id === selectedRouteId) || routes[0];

  // Get first/last departure from schedule
  const firstDep = schedules.length > 0 ? schedules[0].departureTime : null;
  const lastDep = schedules.length > 0 ? schedules[schedules.length - 1].departureTime : null;

  return (
    <div className="timetable-page">
      <div className="timetable-header">
        <div>
          <h2>TMT Bus Timetable</h2>
          <p className="subtitle">Official departure schedules for Thane Municipal Transport routes</p>
        </div>
      </div>

      {loading && <LoadingState message="Loading TMT timetables..." />}
      {error && <ErrorState message={error} />}

      {!loading && !error && (
        <div className="timetable-layout">
          {/* Route selector list */}
          <div className="route-picker-column">
            <div className="picker-search-box">
              <input
                type="text"
                placeholder="Search routes..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <div className="picker-count">{filteredRoutes.length} routes</div>
            <div className="picker-list">
              {filteredRoutes.map((route) => (
                <button
                  key={route.id}
                  className={`picker-item ${selectedRouteId === route.id ? 'active' : ''}`}
                  onClick={() => setSelectedRouteId(route.id)}
                >
                  <div className="picker-item-top">
                    <span className="picker-num">🚌 {route.routeNumber}</span>
                    {route.direction && (
                      <span className="picker-dir">{route.direction}</span>
                    )}
                  </div>
                  <div className="picker-path">{route.source} → {route.destination}</div>
                  <div className="picker-stops">{route.stopsCount} stops</div>
                </button>
              ))}
            </div>
          </div>

          {/* Active Route Detailed Timetable */}
          {activeRoute && (
            <div className="timetable-detail-column">
              <div className="timetable-card">
                <div className="card-top-header">
                  <div>
                    <span className="badge">🚌 TMT BUS</span>
                    <h2 className="title">
                      Route {activeRoute.routeNumber}: {activeRoute.source} → {activeRoute.destination}
                    </h2>
                    {activeRoute.direction && (
                      <span className="direction-tag">{activeRoute.direction} direction</span>
                    )}
                  </div>
                  <div className="card-actions">
                    <button
                      className="details-btn"
                      onClick={() => onSelectRoute(activeRoute)}
                    >
                      View Details
                    </button>
                    <button className="track-btn" onClick={() => onTrackBus(activeRoute)}>
                      Track Live ➔
                    </button>
                  </div>
                </div>

                <div className="schedule-summary-metrics">
                  <div className="metric">
                    <span>First Bus</span>
                    <strong>🌅 {firstDep || '—'}</strong>
                  </div>
                  <div className="metric">
                    <span>Last Bus</span>
                    <strong>🌙 {lastDep || '—'}</strong>
                  </div>
                  <div className="metric">
                    <span>Total Trips</span>
                    <strong>⚡ {schedules.length}</strong>
                  </div>
                  <div className="metric">
                    <span>Stops</span>
                    <strong>🛑 {activeRoute.stopsCount}</strong>
                  </div>
                </div>

                {/* Upcoming Departure Grid */}
                <h3 className="upcoming-heading">All Scheduled Departures (GTFS)</h3>

                {schedulesLoading && <LoadingState message="Loading schedules..." />}

                {!schedulesLoading && (
                  <div className="departure-grid">
                    {schedules.map((sch, i) => (
                      <div key={sch.id || i} className={`departure-card ${i === 0 ? 'highlight-next' : ''}`}>
                        <div className="time">{sch.departureTime}</div>
                        {i === 0 && <span className="next-badge">FIRST BUS</span>}
                      </div>
                    ))}

                    {schedules.length === 0 && (
                      <div className="no-schedules">
                        No GTFS schedule data for this route. Check back later.
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
