import { useState, useEffect } from 'react';
import { api } from '../services/api';

export function useLiveBuses(pollInterval = 3000) {
  const [buses, setBuses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let isMounted = true;

    async function loadBuses() {
      try {
        const data = await api.getLiveBuses();
        if (isMounted) {
          setBuses(data);
          setError(null);
        }
      } catch (err) {
        if (isMounted) {
          setError('Failed to fetch live bus locations');
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    }

    loadBuses();
    const interval = setInterval(loadBuses, pollInterval);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [pollInterval]);

  return { buses, loading, error };
}

export function useSingleBusTracking(busId, pollInterval = 3000) {
  const [busLocation, setBusLocation] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!busId) return;
    let isMounted = true;

    async function loadBusLocation() {
      try {
        const data = await api.getBusLocation(busId);
        if (isMounted) {
          setBusLocation(data);
          setError(null);
        }
      } catch (err) {
        if (isMounted) {
          setError('Failed to track bus location');
        }
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    }

    loadBusLocation();
    const interval = setInterval(loadBusLocation, pollInterval);

    return () => {
      isMounted = false;
      clearInterval(interval);
    };
  }, [busId, pollInterval]);

  return { busLocation, loading, error };
}
