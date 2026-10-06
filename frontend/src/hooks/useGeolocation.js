import { useState, useEffect } from 'react';

export function useGeolocation() {
  const [location, setLocation] = useState({
    latitude: 19.1860, // Default Thane Station
    longitude: 72.9759,
    loaded: false,
    error: null,
  });

  const getLocation = () => {
    if (!navigator.geolocation) {
      setLocation((prev) => ({
        ...prev,
        loaded: true,
        error: 'Geolocation is not supported by your browser',
      }));
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setLocation({
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude,
          loaded: true,
          error: null,
        });
      },
      (err) => {
        setLocation((prev) => ({
          ...prev,
          loaded: true,
          error: err.message,
        }));
      }
    );
  };

  useEffect(() => {
    getLocation();
  }, []);

  return { ...location, refreshLocation: getLocation };
}
