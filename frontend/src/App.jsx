import { useState, useEffect } from 'react';
import Navbar from './components/Navbar';
import Home from './pages/Home';
import SearchResults from './pages/SearchResults';
import RouteDetails from './pages/RouteDetails';
import LiveTracking from './pages/LiveTracking';
import BusDetails from './pages/BusDetails';
import Timetable from './pages/Timetable';
import Profile from './pages/Profile';
import { useGeolocation } from './hooks/useGeolocation';
import { api } from './services/api';
import './App.css';
import './modern-ui.css';

export default function App() {
  const [activeTab, setActiveTab] = useState('HOME');
  const [searchParams, setSearchParams] = useState({ from: '', to: '' });
  const [selectedRoute, setSelectedRoute] = useState(null);
  const [selectedBus, setSelectedBus] = useState(null);
  const [popularRoutes, setPopularRoutes] = useState([]);
  const [popularRoutesLoading, setPopularRoutesLoading] = useState(true);
  const [popularRoutesError, setPopularRoutesError] = useState('');
  const [routeRefreshToken, setRouteRefreshToken] = useState(0);
  const userLocation = useGeolocation();

  // Load initial popular routes for home screen
  useEffect(() => {
    let active = true;
    api.getAllRoutes().then((data) => {
      if (active) {
        setPopularRoutes(data);
        setPopularRoutesError('');
      }
    }).catch((err) => {
      if (active) {
        console.error('Error loading popular routes:', err);
        setPopularRoutesError('Route data could not be loaded. Check the transit service and try again.');
      }
    }).finally(() => {
      if (active) setPopularRoutesLoading(false);
    });
    return () => { active = false; };
  }, [routeRefreshToken]);

  const retryPopularRoutes = () => {
    setPopularRoutesLoading(true);
    setPopularRoutesError('');
    setRouteRefreshToken((token) => token + 1);
  };

  // Handler for route search submit
  const handleSearch = (params) => {
    setSearchParams(params);
    setActiveTab('SEARCH');
  };

  // Handler to open route details page
  const handleSelectRoute = (route) => {
    setSelectedRoute(route);
    setActiveTab('ROUTE_DETAILS');
  };

  // Handler to open live bus tracking map
  const handleTrackBus = (routeOrBus) => {
    if (routeOrBus.routeNumber) {
      setSelectedRoute(routeOrBus);
    }
    if (routeOrBus.busId) {
      setSelectedBus(routeOrBus);
    }
    setActiveTab('LIVE');
  };

  // Handler to view full bus details page
  const handleSelectBus = (bus) => {
    setSelectedBus(bus);
    setActiveTab('BUS_DETAILS');
  };

  return (
    <div className="app-layout">
      {/* Top Header Navbar */}
      <Navbar activeTab={activeTab} setActiveTab={setActiveTab} />

      {/* Main App Workspace Area */}
      <main className={`app-main-content ${activeTab === 'HOME' ? 'home-main-content' : ''}`}>
        {activeTab === 'HOME' && (
          <Home
            userLocation={userLocation}
            popularRoutes={popularRoutes}
            popularRoutesLoading={popularRoutesLoading}
            popularRoutesError={popularRoutesError}
            onRetryRoutes={retryPopularRoutes}
          />
        )}

        {activeTab === 'SEARCH' && (
          <SearchResults
            searchParams={searchParams}
            onSearch={handleSearch}
            onSelectRoute={handleSelectRoute}
            onTrackBus={handleTrackBus}
          />
        )}

        {activeTab === 'ROUTE_DETAILS' && (
          <RouteDetails
            route={selectedRoute}
            onTrackBus={handleTrackBus}
            onBack={() => setActiveTab('SEARCH')}
          />
        )}

        {activeTab === 'LIVE' && (
          <LiveTracking
            selectedRoute={selectedRoute}
            selectedBus={selectedBus}
            onViewBusDetails={handleSelectBus}
            userLocation={userLocation}
          />
        )}

        {activeTab === 'BUS_DETAILS' && (
          <BusDetails
            bus={selectedBus}
            onTrackLive={handleTrackBus}
            onViewRoute={handleSelectRoute}
            onBack={() => setActiveTab('LIVE')}
          />
        )}

        {activeTab === 'ROUTES' && (
          <Timetable
            onSelectRoute={handleSelectRoute}
            onTrackBus={handleTrackBus}
          />
        )}

        {activeTab === 'PROFILE' && (
          <Profile onSelectRoute={handleSelectRoute} />
        )}
      </main>
    </div>
  );
}