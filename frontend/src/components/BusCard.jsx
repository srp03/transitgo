import React from 'react';

export default function BusCard({ bus, onViewBusDetails, onClose = null }) {
  if (!bus) return null;

  const isTrain = bus.transportType === 'TRAIN';

  return (
    <div className="bus-floating-card">
      {onClose && (
        <button className="close-card-btn" onClick={onClose}>
          ✕
        </button>
      )}

      <div className="bus-card-header">
        <div className="bus-title-group">
          <span className={`bus-type-icon ${isTrain ? 'train' : 'bus'}`}>
            {isTrain ? '🚆' : '🚌'}
          </span>
          <div>
            <h3 className="bus-route-number">{bus.routeNumber}</h3>
            <p className="bus-vehicle-reg">{bus.vehicleNumber || 'MH-04-AB-1234'}</p>
          </div>
        </div>

        <div className="eta-highlight-badge">
          ETA: {bus.etaMinutes} min
        </div>
      </div>

      <div className="bus-route-path">
        {bus.source} → {bus.destination}
      </div>

      <div className="bus-info-metrics">
        <div className="metric-item">
          <span className="metric-label">Status</span>
          <span className="metric-value status-on-time">● {bus.status || 'On time'}</span>
        </div>

        <div className="metric-item">
          <span className="metric-label">Speed</span>
          <span className="metric-value">{Math.round(bus.speed || 28)} km/h</span>
        </div>

        <div className="metric-item">
          <span className="metric-label">Capacity</span>
          <span className="metric-value">{bus.occupancyStatus || 'Moderate'}</span>
        </div>
      </div>

      <div className="bus-current-stop-alert">
        <span>📍 Current: <strong>{bus.currentStopName || 'En route'}</strong></span>
        <span>➡️ Next: <strong>{bus.nextStopName || 'Destination'}</strong></span>
      </div>

      <button
        className="view-bus-full-btn"
        onClick={() => onViewBusDetails(bus)}
      >
        VIEW BUS DETAILS ➔
      </button>
    </div>
  );
}
