const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api';

async function fetchJson(endpoint) {
  try {
    const res = await fetch(`${API_BASE_URL}${endpoint}`);
    if (!res.ok) {
      throw new Error(`Server returned ${res.status}`);
    }
    return await res.json();
  } catch (err) {
    console.error(`API Error on ${endpoint}:`, err);
    throw err;
  }
}

export const api = {
  // Routes
  getAllRoutes: () => fetchJson('/routes'),
  getRouteById: (id) => fetchJson(`/routes/${id}`),
  searchRoutes: (from = '', to = '') =>
    fetchJson(`/routes/search?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`),
  getRouteStops: (id) => fetchJson(`/routes/${id}/stops`),
  getRouteSchedules: (id) => fetchJson(`/routes/${id}/schedule`),
  getRouteBuses: (id) => fetchJson(`/routes/${id}/buses`),

  // Buses
  getAllBuses: () => fetchJson('/buses'),
  getBusById: (id) => fetchJson(`/buses/${id}`),
  getLiveBuses: () => fetchJson('/buses/live'),
  getBusLocation: (id) => fetchJson(`/buses/${id}/location`),

  // Stops
  getAllStops: () => fetchJson('/stops'),
  getNearbyStops: (lat, lng, radius = 5.0) =>
    fetchJson(`/stops/nearby?lat=${lat}&lng=${lng}&radius=${radius}`),
  searchStops: (query) => fetchJson(`/stops/search?query=${encodeURIComponent(query)}`),
};
