import React from 'react';

export function LoadingState({ message = 'Loading transit data...' }) {
  return (
    <div className="state-container loading">
      <div className="spinner-ring"></div>
      <p className="state-message">{message}</p>
    </div>
  );
}

export function EmptyState({ title = 'No routes found', message = 'Try searching with a different origin or destination.' }) {
  return (
    <div className="state-container empty">
      <div className="empty-icon">🚏</div>
      <h4>{title}</h4>
      <p>{message}</p>
    </div>
  );
}

export function ErrorState({ title = 'Unable to connect', message = 'Could not reach TransitGo servers. Please verify backend is running.', onRetry = null }) {
  return (
    <div className="state-container error">
      <div className="error-icon">⚠️</div>
      <h4>{title}</h4>
      <p>{message}</p>
      {onRetry && (
        <button className="retry-btn" onClick={onRetry}>
          Try Again 🔄
        </button>
      )}
    </div>
  );
}
