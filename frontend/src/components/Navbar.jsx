import React from 'react';

export default function Navbar({ activeTab, setActiveTab }) {
  const navItems = [
    { id: 'HOME', label: 'Home', icon: '🏠' },
    { id: 'SEARCH', label: 'Search', icon: '🔍' },
    { id: 'LIVE', label: 'Live Map', icon: '📡' },
    { id: 'ROUTES', label: 'Timetable', icon: '🗺️' },
    { id: 'PROFILE', label: 'Profile', icon: '👤' },
  ];

  return (
    <>
      {/* Desktop Navigation Top Bar */}
      <header className="desktop-navbar">
        <div className="navbar-brand" onClick={() => setActiveTab('HOME')}>
          <div className="logo-icon">🚌</div>
          <div className="logo-text">
            <span className="brand-name">TransitGo</span>
            <span className="brand-badge">INDIA</span>
          </div>
        </div>

        <nav className="desktop-nav-links">
          {navItems.map((item) => (
            <button
              key={item.id}
              className={`nav-link ${activeTab === item.id ? 'active' : ''}`}
              onClick={() => setActiveTab(item.id)}
            >
              <span className="nav-icon">{item.icon}</span>
              <span>{item.label}</span>
            </button>
          ))}
        </nav>

        <div className="navbar-actions">
          <div className="live-status-pill">
            <span className="pulse-green"></span> Live Engine Active
          </div>
        </div>
      </header>

      {/* Mobile Bottom Navigation Bar */}
      <nav className="mobile-bottom-nav">
        {navItems.map((item) => (
          <button
            key={item.id}
            className={`mobile-nav-item ${activeTab === item.id ? 'active' : ''}`}
            onClick={() => setActiveTab(item.id)}
          >
            <span className="mobile-nav-icon">{item.icon}</span>
            <span className="mobile-nav-label">{item.label}</span>
          </button>
        ))}
      </nav>
    </>
  );
}
