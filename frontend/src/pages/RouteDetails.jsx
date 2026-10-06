import { useState, useEffect } from 'react';
import RouteTimeline from '../components/RouteTimeline';
import { api } from '../services/api';
import { LoadingState, ErrorState } from '../components/States';

export default function RouteDetails({ route, onTrackBus, onBack }) {
  const [stops, setStops] = useState([]);
  const [schedules, setSchedules] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!route || !route.id) return;
    let isMounted = true;

    async function loadRouteDetails() {
      setLoading(true);
      setError(null);
      try {
        const [stopsData, schedulesData] = await Promise.all([
          api.getRouteStops(route.id),
          api.getRouteSchedules(route.id).catch(() => [])  // graceful fallback
        ]);

        if (isMounted) {
          setStops(stopsData);
          setSchedules(schedulesData);
        }
      } catch (err) {
        if (isMounted) {
          setError('Failed to load route stops & timetable.');
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    }

    loadRouteDetails();

    return () => {
      isMounted = false;
    };
  }, [route]);

  if (!route) return null;

  const firstDep = schedules.length > 0 ? schedules[0].departureTime : null;
  const lastDep = schedules.length > 0 ? schedules[schedules.length - 1].departureTime : null;

  return (
    <div className="route-details-page">
      {/* Top Header Card */}
      <div className="details-header-card">
        <button className="back-btn" onClick={onBack}>
          ← Back to Search
        </button>

        <div className="route-title-banner">
          <div className="banner-left">
            <span className="transport-badge-lg bus">🚌 TMT BUS</span>
            <h1 className="route-num-heading">Route {route.routeNumber}</h1>
          </div>

          <button
            className="track-live-cta-btn"
            onClick={() => onTrackBus(route)}
          >
            📡 TRACK LIVE (DEMO)
          </button>
        </div>

        <h2 className="route-origin-dest">
          {route.source} <span className="arrow">➔</span> {route.destination}
        </h2>

        {route.direction && (
          <span className="direction-chip">{route.direction} Direction</span>
        )}

        <div className="metrics-row-bar">
          <div className="bar-item">
            <span className="bar-label">Agency</span>
            <span className="bar-val">TMT — Thane</span>
          </div>

          <div className="bar-item">
            <span className="bar-label">First Bus</span>
            <span className="bar-val">{firstDep || (loading ? '...' : 'N/A')}</span>
          </div>

          <div className="bar-item">
            <span className="bar-label">Last Bus</span>
            <span className="bar-val">{lastDep || (loading ? '...' : 'N/A')}</span>
          </div>

          <div className="bar-item">
            <span className="bar-label">Stops</span>
            <span className="bar-val">{stops.length > 0 ? stops.length : route.stopsCount || '—'}</span>
          </div>

          <div className="bar-item">
            <span className="bar-label">Total Trips</span>
            <span className="bar-val">{schedules.length > 0 ? schedules.length : '—'}</span>
          </div>
        </div>
      </div>

      {/* Main Grid Content */}
      <div className="details-grid-layout">
        {/* Left: Stops Timeline */}
        <div className="timeline-section-card">
          <h3 className="section-heading">Route Stops ({stops.length})</h3>
          {loading && <LoadingState message="Fetching route stops..." />}
          {error && <ErrorState message={error} />}

          {!loading && !error && (
            <RouteTimeline
              stops={stops.length > 0 ? stops : route.stops || []}
              currentStopName={stops[0]?.name || route.source}
              nextStopName={stops[1]?.name || ''}
            />
          )}
        </div>

        {/* Right: Timetable & Service Info */}
        <div className="info-sidebar-column">
          <div className="sidebar-card">
            <h3>Service Information</h3>
            <div className="timing-info-row">
              <span>Route ID:</span>
              <strong>{route.gtfsRouteId || route.id}</strong>
            </div>
            <div className="timing-info-row">
              <span>First Departure:</span>
              <strong>{firstDep || 'N/A'}</strong>
            </div>
            <div className="timing-info-row">
              <span>Last Departure:</span>
              <strong>{lastDep || 'N/A'}</strong>
            </div>
            <div className="timing-info-row">
              <span>Fare:</span>
              <strong>{route.fareInfo || 'Check TMT website'}</strong>
            </div>
          </div>

          <div className="sidebar-card">
            <h3>Upcoming Departures (GTFS)</h3>
            <div className="upcoming-chips-grid">
              {schedules.slice(0, 8).map((sch, i) => (
                <div key={sch.id || i} className={`time-chip ${i === 0 ? 'next' : ''}`}>
                  {sch.departureTime}
                  {i === 0 && <span className="chip-badge">First</span>}
                </div>
              ))}
              {schedules.length === 0 && !loading && (
                <div className="no-schedules-msg">Schedule data not available</div>
              )}
              {loading && <div className="no-schedules-msg">Loading...</div>}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
