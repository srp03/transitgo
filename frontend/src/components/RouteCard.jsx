import React from 'react';

export default function RouteCard({ route, onViewRoute, onTrackBus }) {
  const isTrain = route.transportType === 'TRAIN';

  return (
    <div className="route-card-item">
      <div className="route-card-top">
        <div className="route-badge-row">
          <span className={`transport-badge ${isTrain ? 'train' : 'bus'}`}>
            {isTrain ? '🚆 TRAIN' : '🚌 BUS'}
          </span>
          <span className="route-number-tag">{route.routeNumber}</span>
        </div>

        <div className="next-bus-eta-badge">
          <span className="live-dot-pulse"></span>
          Next in <strong>{route.nextBusEtaMinutes || route.nextBusTime || '8 min'}</strong>
        </div>
      </div>

      <div className="route-card-body">
        <h4 className="route-path-title">
          {route.source} <span className="arrow">→</span> {route.destination}
        </h4>

        <div className="route-stats-grid">
          <div className="stat-box">
            <span className="stat-label">Travel Time</span>
            <span className="stat-value">⏱️ {route.estimatedDuration} min</span>
          </div>

          <div className="stat-box">
            <span className="stat-label">Stops</span>
            <span className="stat-value">🚏 {route.stopsCount || 4} stops</span>
          </div>

          <div className="stat-box">
            <span className="stat-label">Fare</span>
            <span className="stat-value fare">₹{route.fare}</span>
          </div>
        </div>
      </div>

      <div className="route-card-actions">
        <button
          className="secondary-btn"
          onClick={() => onViewRoute(route)}
        >
          VIEW ROUTE
        </button>

        <button
          className="primary-track-btn"
          onClick={() => onTrackBus(route)}
        >
          <span>📍</span> TRACK BUS
        </button>
      </div>
    </div>
  );
}
