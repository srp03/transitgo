import { useState, useEffect } from 'react';
import RouteTimeline from '../components/RouteTimeline';
import { useSingleBusTracking } from '../hooks/useBusTracking';
import { api } from '../services/api';
import { LoadingState, ErrorState } from '../components/States';

export default function BusDetails({ bus, onTrackLive, onViewRoute, onBack }) {
  const busId = bus?.busId || bus?.id;
  const { busLocation, loading: trackingLoading } = useSingleBusTracking(busId, 3000);
  const [stops, setStops] = useState([]);

  useEffect(() => {
    if (!bus || !bus.routeId) return;
    let isMounted = true;
    async function loadStops() {
      try {
        const data = await api.getRouteStops(bus.routeId);
        if (isMounted) setStops(data);
      } catch (err) {
        console.error('Error fetching stops:', err);
      }
    }
    loadStops();
    return () => { isMounted = false; };
  }, [bus]);

  if (!bus) {
    return (
      <div className="bus-details-page">
        <button className="back-btn" onClick={onBack}>← Back</button>
        <ErrorState message="No bus selected." />
      </div>
    );
  }

  const currentData = busLocation || bus;
  const isTrain = currentData.transportType === 'TRAIN';

  return (
    <div className="bus-details-page">
      <button className="back-btn" onClick={onBack}>
        ← Back
      </button>

      {/* Top Banner */}
      <div className="bus-details-header">
        <div className="bus-header-left">
          <span className={`vehicle-badge-lg ${isTrain ? 'train' : 'bus'}`}>
            {isTrain ? '🚆 TRAIN' : '🚌 BUS'}
          </span>
          <div>
            <h1>{currentData.routeNumber || 'T101'}</h1>
            <p className="reg-number">{currentData.vehicleNumber || 'MH-04-AB-1234'}</p>
          </div>
        </div>

        <div className="bus-header-actions">
          <button className="secondary-action-btn" onClick={() => onViewRoute({ id: currentData.routeId })}>
            VIEW ROUTE
          </button>

          <button className="primary-track-live-btn" onClick={() => onTrackLive(currentData)}>
            📡 TRACK LIVE
          </button>
        </div>
      </div>

      {/* Live Operational Metrics Grid */}
      <div className="bus-metrics-banner">
        <div className="metric-card">
          <span className="label">Current Location</span>
          <strong className="value location">📍 {currentData.currentStopName || 'En route'}</strong>
        </div>

        <div className="metric-card">
          <span className="label">Next Stop</span>
          <strong className="value">➡️ {currentData.nextStopName || 'Destination'}</strong>
        </div>

        <div className="metric-card">
          <span className="label">ETA</span>
          <strong className="value highlight">{currentData.etaMinutes || 8} min</strong>
        </div>

        <div className="metric-card">
          <span className="label">Speed</span>
          <strong className="value">{Math.round(currentData.speed || 26)} km/h</strong>
        </div>

        <div className="metric-card">
          <span className="label">Status</span>
          <strong className="value status-on-time">● {currentData.status || 'On time'}</strong>
        </div>
      </div>

      {/* Grid: Route Progress & Vehicle Specs */}
      <div className="bus-details-grid">
        {/* Left Column: Progress Timeline */}
        <div className="timeline-card-wrapper">
          <RouteTimeline
            stops={stops}
            currentStopName={currentData.currentStopName}
            nextStopName={currentData.nextStopName}
          />
        </div>

        {/* Right Column: Vehicle Information */}
        <div className="specs-card-wrapper">
          <div className="specs-card">
            <h3>Vehicle Details</h3>

            <div className="spec-row">
              <span className="spec-label">Bus / Vehicle Number</span>
              <span className="spec-val font-mono">{currentData.vehicleNumber || 'MH-04-AB-1234'}</span>
            </div>

            <div className="spec-row">
              <span className="spec-label">Vehicle Type</span>
              <span className="spec-val">{currentData.vehicleType || 'Electric AC'}</span>
            </div>

            <div className="spec-row">
              <span className="spec-label">Total Capacity</span>
              <span className="spec-val">{currentData.capacity || 40} seats</span>
            </div>

            <div className="spec-row">
              <span className="spec-label">Current Occupancy</span>
              <span className="spec-val badge-occupancy">{currentData.occupancyStatus || 'Moderate'}</span>
            </div>

            <div className="spec-row">
              <span className="spec-label">Air Conditioning (AC)</span>
              <span className="spec-val">{currentData.vehicleType?.includes('AC') ? '✅ Yes (Climate Controlled)' : '❌ Non-AC'}</span>
            </div>

            <div className="spec-row">
              <span className="spec-label">Accessibility</span>
              <span className="spec-val">♿ Low Floor Wheelchair Accessible</span>
            </div>

            <div className="spec-row">
              <span className="spec-label">GPS Hardware Mode</span>
              <span className="spec-val mock-mode-badge">⚡ Mock Live Simulation</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
