import { useState } from 'react';

export default function SearchCard({
  onSearch,
  initialFrom = '',
  initialTo = '',
  onUseLocation = null
}) {
  const [from, setFrom] = useState(initialFrom);
  const [to, setTo] = useState(initialTo);

  const handleSwap = () => {
    const temp = from;
    setFrom(to);
    setTo(temp);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSearch({ from, to });
  };

  return (
    <div className="search-card-container">
      <div className="search-header">
        <span className="search-brand-icon">🚌</span>
        <h3>Find TMT Bus Routes</h3>
        {onUseLocation && (
          <button
            type="button"
            className="use-location-btn"
            onClick={() => {
              onUseLocation();
              setFrom('Thane Station');
            }}
          >
            📍 Use Location
          </button>
        )}
      </div>

      <form onSubmit={handleSubmit} className="search-form">
        <div className="inputs-row">
          <div className="input-field-group">
            <label className="field-label">FROM</label>
            <div className="input-with-icon">
              <span className="input-icon origin">🟢</span>
              <input
                type="text"
                placeholder="Starting stop (e.g. Thane Station)"
                value={from}
                onChange={(e) => setFrom(e.target.value)}
              />
            </div>
          </div>

          <button
            type="button"
            className="swap-btn"
            onClick={handleSwap}
            title="Swap Origin & Destination"
          >
            ⇄
          </button>

          <div className="input-field-group">
            <label className="field-label">TO</label>
            <div className="input-with-icon">
              <span className="input-icon destination">🔴</span>
              <input
                type="text"
                placeholder="Destination (e.g. Airoli, Mulund)"
                value={to}
                onChange={(e) => setTo(e.target.value)}
              />
            </div>
          </div>
        </div>

        <div className="search-hints">
          <span>Try: Thane → Airoli</span>
          <span>•</span>
          <span>Thane → Mulund</span>
          <span>•</span>
          <span>Thane → Vashi</span>
        </div>

        <button type="submit" className="primary-search-cta">
          🔍 Find TMT Buses ➔
        </button>
      </form>
    </div>
  );
}
