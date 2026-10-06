import { useEffect, useState } from 'react';

function readBookings() {
  const value = window.localStorage.getItem('transitgo-bookings');
  if (!value) return [];
  const bookings = JSON.parse(value);
  if (!Array.isArray(bookings)) throw new Error('Booking history is not in the expected format.');
  return bookings;
}

export default function Profile() {
  const [bookings, setBookings] = useState([]);
  const [historyError, setHistoryError] = useState('');
  const [emailUpdates, setEmailUpdates] = useState(false);
  const [logoutMessage, setLogoutMessage] = useState('');

  useEffect(() => {
    function loadBookings() {
      try {
        setBookings(readBookings());
        setHistoryError('');
      } catch (error) {
        console.error('Could not load booking history:', error);
        setHistoryError('Booking history could not be read from this browser.');
      }
    }
    loadBookings();
    window.addEventListener('transitgo-bookings-updated', loadBookings);
    window.addEventListener('storage', loadBookings);
    return () => {
      window.removeEventListener('transitgo-bookings-updated', loadBookings);
      window.removeEventListener('storage', loadBookings);
    };
  }, []);

  return (
    <main className="profile-page profile-page-clean">
      <header className="profile-page-heading">
        <span className="eyebrow">YOUR ACCOUNT</span>
        <h1>Profile &amp; preferences</h1>
        <p>Manage your demo account and recent travel.</p>
      </header>
      <div className="profile-clean-layout">
        <section className="profile-user-card">
          <div className="profile-user-avatar">RS</div>
          <div className="profile-user-copy">
            <span className="profile-demo-tag">DEMO PROFILE</span>
            <h2>Rahul Sharma</h2>
            <p>rahul.sharma@transitgo.in</p>
            <span className="profile-location">Thane · Mumbai Metropolitan Region</span>
          </div>
          <button type="button" className="profile-logout-button" onClick={() => setLogoutMessage('This is a demo profile. There is no active account session to sign out of.')}>Log out</button>
          {logoutMessage && <p className="profile-inline-notice" role="status">{logoutMessage}</p>}
        </section>

        <section className="profile-content-card">
          <div className="profile-section-heading"><div><h2>My tickets</h2><p>Your recent bookings on this device</p></div><span className="profile-count">{bookings.length}</span></div>
          {historyError && <p className="profile-history-error" role="alert">{historyError}</p>}
          {!historyError && bookings.length === 0 && (
            <div className="profile-history-empty"><span>▤</span><strong>No tickets yet</strong><p>Tickets you book will be saved here for this browser.</p></div>
          )}
          {!historyError && bookings.length > 0 && (
            <div className="profile-bookings-list">
              {bookings.map((booking) => (
                <article className="profile-booking-row" key={booking.bookingId}>
                  <div className="booking-route-icon">BUS<br /><strong>{booking.routeNumber}</strong></div>
                  <div className="profile-booking-main">
                    <strong>{booking.source} <span>→</span> {booking.destination}</strong>
                    <small>{new Date(booking.departureAt).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })} · {booking.passengers} {booking.passengers === 1 ? 'passenger' : 'passengers'}</small>
                    <small className="booking-pnr-line">PNR {booking.bookingId}</small>
                  </div>
                  <strong className="profile-booking-fare">₹{booking.fare}</strong>
                </article>
              ))}
            </div>
          )}
        </section>

        <section className="profile-content-card">
          <div className="profile-section-heading"><div><h2>Settings</h2><p>Choose how TransitGo works for you</p></div></div>
          <label className="profile-setting-row">
            <span><strong>Service updates</strong><small>Receive route and service notices in this demo</small></span>
            <input type="checkbox" checked={emailUpdates} onChange={(event) => setEmailUpdates(event.target.checked)} />
          </label>
          <div className="profile-setting-row profile-about-row">
            <span><strong>About TransitGo</strong><small>Transit discovery powered by available GTFS schedules</small></span>
            <span className="profile-version">Version 1.0</span>
          </div>
          <p className="profile-data-note">Bus positions shown in this application are schedule-based simulations, not real-time GPS.</p>
        </section>

        <section className="profile-content-card profile-saved-routes">
          <div className="profile-section-heading"><div><h2>Saved routes</h2><p>Quick access to routes you use often</p></div></div>
          <div className="profile-history-empty"><span>☆</span><strong>No saved routes</strong><p>Route saving is not available for this demo profile.</p></div>
        </section>
      </div>
    </main>
  );
}
