import React from 'react';

export default function RouteTimeline({ stops = [], currentStopName = '', nextStopName = '' }) {
  if (!stops || stops.length === 0) {
    return <div className="empty-timeline">No stop information available.</div>;
  }

  // Find index of current stop
  let currentIndex = stops.findIndex(
    (s) => s.name.toLowerCase() === currentStopName.toLowerCase()
  );
  if (currentIndex === -1) currentIndex = 0; // Default first stop as current if not found

  return (
    <div className="route-timeline-container">
      <h3 className="timeline-title">Route Stops & Progress</h3>

      <div className="timeline-list">
        {stops.map((stop, index) => {
          let statusState = 'upcoming'; // departed, current, upcoming
          let statusText = '○ Upcoming';

          if (index < currentIndex) {
            statusState = 'departed';
            statusText = '✓ Departed';
          } else if (index === currentIndex) {
            statusState = 'current';
            statusText = '● Current Stop';
          } else if (index === currentIndex + 1 && nextStopName) {
            statusText = '➔ Next Stop';
          }

          return (
            <div key={stop.id || index} className={`timeline-step ${statusState}`}>
              <div className="timeline-left">
                <div className={`timeline-node ${statusState}`}>
                  {statusState === 'departed' && '✓'}
                  {statusState === 'current' && '●'}
                  {statusState === 'upcoming' && (index + 1)}
                </div>
                {index < stops.length - 1 && <div className={`timeline-line ${index < currentIndex ? 'completed' : ''}`} />}
              </div>

              <div className="timeline-content">
                <div className="stop-name-row">
                  <span className="stop-name">{stop.name}</span>
                  <span className={`stop-status-pill ${statusState}`}>{statusText}</span>
                </div>
                {(stop.arrivalTime || stop.departureTime) && (
                  <div className="stop-times">
                    <span>Arr: {stop.arrivalTime || '--:--'}</span>
                    <span>Dep: {stop.departureTime || '--:--'}</span>
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
