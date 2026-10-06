import { useEffect, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// Fix default leaflet marker icon assets
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

function escapePopupText(value) {
  return String(value ?? '').replace(/[&<>"']/g, (character) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;'
  })[character]);
}

export default function MapView({
  buses = [],
  stops = [],
  nearbyStops = [],
  routeEndpoints = [],
  selectedBus = null,
  onSelectBus = () => {},
  onSelectStop = () => {},
  onSelectNearbyStop = () => {},
  focusStop = null,
  userLocation = null,
  height = '100%',
  center = null,
  zoom = 13
}) {
  const mapContainerRef = useRef(null);
  const mapInstanceRef = useRef(null);
  const markersRef = useRef({});
  const polylineRef = useRef(null);
  const stopMarkersRef = useRef([]);
  const nearbyStopMarkersRef = useRef([]);
  const endpointMarkersRef = useRef([]);
  const userMarkerRef = useRef(null);
  const onSelectBusRef = useRef(onSelectBus);
  const onSelectStopRef = useRef(onSelectStop);
  const onSelectNearbyStopRef = useRef(onSelectNearbyStop);

  useEffect(() => {
    onSelectBusRef.current = onSelectBus;
  }, [onSelectBus]);

  useEffect(() => {
    onSelectStopRef.current = onSelectStop;
  }, [onSelectStop]);

  useEffect(() => {
    onSelectNearbyStopRef.current = onSelectNearbyStop;
  }, [onSelectNearbyStop]);

  // Initialize Map
  useEffect(() => {
    if (!mapContainerRef.current) return;
    if (mapInstanceRef.current) return;

    const initialCenter = center || [19.1860, 72.9759]; // Thane default
    const map = L.map(mapContainerRef.current, {
      center: initialCenter,
      zoom: zoom,
      zoomControl: false
    });

    // Add Tile Layer with OSM
    const tileLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    });

    tileLayer.addTo(map);

    // Zoom control on top right
    L.control.zoom({ position: 'topright' }).addTo(map);

    mapInstanceRef.current = map;
    const container = mapContainerRef.current;
    let resizeFrame = 0;
    const resizeObserver = new ResizeObserver(() => {
      cancelAnimationFrame(resizeFrame);
      resizeFrame = requestAnimationFrame(() => {
        map.invalidateSize({ pan: false });
      });
    });
    resizeObserver.observe(container);
    resizeFrame = requestAnimationFrame(() => {
      map.invalidateSize({ pan: false });
    });

    return () => {
      resizeObserver.disconnect();
      cancelAnimationFrame(resizeFrame);
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, [center, zoom]);

  // Update Center if requested
  useEffect(() => {
    if (mapInstanceRef.current && center) {
      mapInstanceRef.current.flyTo(center, zoom, { duration: 1 });
    }
  }, [center, zoom]);

  useEffect(() => {
    if (mapInstanceRef.current && focusStop && Number.isFinite(Number(focusStop.latitude)) && Number.isFinite(Number(focusStop.longitude))) {
      mapInstanceRef.current.flyTo([Number(focusStop.latitude), Number(focusStop.longitude)], 15, { duration: 0.6 });
    }
  }, [focusStop]);

  // Render User Location
  useEffect(() => {
    if (!mapInstanceRef.current) return;
    const map = mapInstanceRef.current;

    if (userLocation && userLocation.latitude && userLocation.longitude) {
      const userIcon = L.divIcon({
        className: 'user-marker-container',
        html: `
          <div class="user-location-dot">
            <div class="user-location-pulse"></div>
            <div class="user-location-core"></div>
          </div>
        `,
        iconSize: [24, 24],
        iconAnchor: [12, 12]
      });

      if (userMarkerRef.current) {
        userMarkerRef.current.setLatLng([userLocation.latitude, userLocation.longitude]);
      } else {
        userMarkerRef.current = L.marker([userLocation.latitude, userLocation.longitude], { icon: userIcon })
          .addTo(map)
          .bindPopup('<b>Your Location</b>');
      }
    }
  }, [userLocation]);

  // Render Route Polyline & Stops
  useEffect(() => {
    if (!mapInstanceRef.current) return;
    const map = mapInstanceRef.current;

    // Clear old polyline
    if (polylineRef.current) {
      map.removeLayer(polylineRef.current);
      polylineRef.current = null;
    }

    // Clear old stop markers
    stopMarkersRef.current.forEach(m => map.removeLayer(m));
    stopMarkersRef.current = [];

    if (stops && stops.length > 0) {
      const coords = stops.map(s => [s.latitude, s.longitude]);

      // Draw polyline
      polylineRef.current = L.polyline(coords, {
        color: '#2563EB',
        weight: 5,
        opacity: 0.85,
        lineCap: 'round',
        lineJoin: 'round',
        dashArray: null
      }).addTo(map);

      // Draw stop markers
      stops.forEach((stop, index) => {
        const isFirst = index === 0;
        const isLast = index === stops.length - 1;

        const stopIcon = L.divIcon({
          className: 'stop-marker-container',
          html: `
            <div class="stop-marker-badge ${isFirst ? 'origin' : isLast ? 'destination' : ''}">
              <div class="stop-marker-dot"></div>
            </div>
          `,
          iconSize: [20, 20],
          iconAnchor: [10, 10]
        });

        const marker = L.marker([stop.latitude, stop.longitude], { icon: stopIcon })
          .addTo(map)
          .bindPopup(`
            <div style="font-family: sans-serif; padding: 4px;">
              <strong style="color: #0F172A; font-size: 14px;">${escapePopupText(stop.name)}</strong>
              <div style="color: #64748B; font-size: 12px; margin-top: 2px;">Stop #${stop.sequence || index + 1}</div>
              ${stop.arrivalTime || stop.departureTime ? `<div style="color: #64748B; font-size: 12px; margin-top: 3px;">${stop.arrivalTime ? `Arrival: ${escapePopupText(stop.arrivalTime)}` : ''}${stop.arrivalTime && stop.departureTime ? ' · ' : ''}${stop.departureTime ? `Departure: ${escapePopupText(stop.departureTime)}` : ''}</div>` : ''}
            </div>
          `);

        marker.on('click', () => onSelectStopRef.current(stop));
        stopMarkersRef.current.push(marker);
      });

      if (coords.length > 0) {
        const bounds = L.latLngBounds(coords);
        map.fitBounds(bounds, { padding: [48, 48], maxZoom: 15 });
      }
    }
  }, [stops]);

  useEffect(() => {
    if (!mapInstanceRef.current) return;
    const map = mapInstanceRef.current;
    nearbyStopMarkersRef.current.forEach((marker) => map.removeLayer(marker));
    nearbyStopMarkersRef.current = [];

    nearbyStops.forEach((stop) => {
      if (!Number.isFinite(Number(stop.latitude)) || !Number.isFinite(Number(stop.longitude))) return;
      const icon = L.divIcon({
        className: 'nearby-stop-marker-container',
        html: '<span class="nearby-stop-marker"></span>',
        iconSize: [22, 22],
        iconAnchor: [11, 11]
      });
      const distance = Number.isFinite(Number(stop.distanceKm))
        ? `<div style="color:#64748B;font-size:12px;margin-top:3px;">${Number(stop.distanceKm).toFixed(2)} km away</div>`
        : '';
      const marker = L.marker([Number(stop.latitude), Number(stop.longitude)], { icon })
        .addTo(map)
        .bindPopup(`
          <div style="font-family:sans-serif;padding:4px;">
            <strong style="color:#0F172A;font-size:14px;">${escapePopupText(stop.name)}</strong>
            <div style="color:#64748B;font-size:12px;margin-top:2px;">Nearby bus stop</div>
            ${distance}
          </div>
        `);
      marker.on('click', () => onSelectNearbyStopRef.current(stop));
      nearbyStopMarkersRef.current.push(marker);
    });

    if (stops.length === 0 && nearbyStops.length > 0) {
      const coordinates = nearbyStops
        .filter((stop) => Number.isFinite(Number(stop.latitude)) && Number.isFinite(Number(stop.longitude)))
        .map((stop) => [Number(stop.latitude), Number(stop.longitude)]);
      if (coordinates.length) map.fitBounds(L.latLngBounds(coordinates), { padding: [48, 48], maxZoom: 15 });
    }
  }, [nearbyStops, stops]);

  useEffect(() => {
    if (!mapInstanceRef.current) return;
    const map = mapInstanceRef.current;
    endpointMarkersRef.current.forEach((marker) => map.removeLayer(marker));
    endpointMarkersRef.current = [];

    routeEndpoints.forEach((stop, index) => {
      if (!Number.isFinite(Number(stop.latitude)) || !Number.isFinite(Number(stop.longitude))) return;
      const endpointLabel = index === 0 ? 'Route origin' : 'Route destination';
      const icon = L.divIcon({
        className: 'stop-marker-container',
        html: `<div class="stop-marker-badge ${index === 0 ? 'origin' : 'destination'}"></div>`,
        iconSize: [20, 20],
        iconAnchor: [10, 10]
      });
      const marker = L.marker([Number(stop.latitude), Number(stop.longitude)], { icon })
        .addTo(map)
        .bindPopup(`<div style="font-family:sans-serif;padding:4px;"><strong>${escapePopupText(stop.name)}</strong><div style="color:#64748B;font-size:12px;">${endpointLabel} · no GTFS trip path available</div></div>`);
      endpointMarkersRef.current.push(marker);
    });

    if (stops.length === 0 && routeEndpoints.length > 0) {
      const coordinates = routeEndpoints
        .filter((stop) => Number.isFinite(Number(stop.latitude)) && Number.isFinite(Number(stop.longitude)))
        .map((stop) => [Number(stop.latitude), Number(stop.longitude)]);
      if (coordinates.length) map.fitBounds(L.latLngBounds(coordinates), { padding: [48, 48], maxZoom: 14 });
    }
  }, [routeEndpoints, stops]);

  // Render & Animate Bus Markers
  useEffect(() => {
    if (!mapInstanceRef.current) return;
    const map = mapInstanceRef.current;

    const currentBusIds = new Set();

    buses.forEach((bus) => {
      if (!bus.latitude || !bus.longitude) return;
      currentBusIds.add(String(bus.busId));

      const isSelected = selectedBus && selectedBus.busId === bus.busId;
      const isTrain = bus.transportType === 'TRAIN';
      const iconEmoji = isTrain ? '🚆' : '🚌';
      const badgeClass = isTrain ? 'train-badge' : 'bus-badge';

      const busIcon = L.divIcon({
        className: 'bus-marker-wrapper',
        html: `
          <div class="bus-marker-card ${isSelected ? 'selected' : ''} ${badgeClass}">
            <span class="bus-number-pill">${escapePopupText(bus.routeNumber)}</span>
            <span class="bus-emoji">${iconEmoji}</span>
            <div class="bus-pulse-ring"></div>
          </div>
        `,
        iconSize: [60, 36],
        iconAnchor: [30, 18]
      });

      if (markersRef.current[bus.busId]) {
        // Animate marker movement smoothly
        const marker = markersRef.current[bus.busId];
        marker.setLatLng([bus.latitude, bus.longitude]);
        marker.setIcon(busIcon);
      } else {
        const marker = L.marker([bus.latitude, bus.longitude], { icon: busIcon })
          .addTo(map);

        marker.on('click', () => onSelectBusRef.current(bus));
        markersRef.current[bus.busId] = marker;
      }
    });

    // Remove old bus markers no longer present
    Object.keys(markersRef.current).forEach((id) => {
      if (!currentBusIds.has(String(id))) {
        map.removeLayer(markersRef.current[id]);
        delete markersRef.current[id];
      }
    });

    // If a bus is selected, center map on it smoothly
    if (selectedBus && selectedBus.latitude && selectedBus.longitude) {
      map.panTo([selectedBus.latitude, selectedBus.longitude], { animate: true, duration: 0.8 });
    }

  }, [buses, selectedBus]);

  return (
    <div style={{ position: 'relative', width: '100%', height: height, borderRadius: '16px', overflow: 'hidden' }}>
      <div ref={mapContainerRef} style={{ width: '100%', height: '100%' }} />

      {/* Recenter Button Overlay */}
      <button
        className="map-recenter-btn"
        onClick={() => {
          if (mapInstanceRef.current) {
            if (selectedBus) {
              mapInstanceRef.current.flyTo([selectedBus.latitude, selectedBus.longitude], 15);
            } else if (userLocation && userLocation.latitude) {
              mapInstanceRef.current.flyTo([userLocation.latitude, userLocation.longitude], 14);
            } else {
              mapInstanceRef.current.flyTo([19.1860, 72.9759], 13);
            }
          }
        }}
        title="Recenter Map"
      >
        🎯
      </button>

      {/* Mock Mode Tag Overlay */}
      {selectedBus && <div className="mock-gps-tag"><span className="mock-dot"></span> SCHEDULE SIMULATION</div>}
    </div>
  );
}
