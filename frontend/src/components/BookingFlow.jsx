import { useEffect, useMemo, useState } from 'react';

function localDateTime(timestamp) {
  const now = new Date(timestamp);
  now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
  return now.toISOString().slice(0, 16);
}

function bookingCode() {
  return `TG${Date.now().toString(36).toUpperCase()}${Math.random().toString(36).slice(2, 5).toUpperCase()}`;
}

function TicketPattern({ value }) {
  const seed = Array.from(value).reduce((total, character) => total + character.charCodeAt(0), 0);
  return (
    <div className="ticket-code-pattern" role="img" aria-label="Decorative ticket code">
      {Array.from({ length: 100 }, (_, index) => {
        const filled = ((seed * (index + 5) + index * index * 13) % 17) < 8;
        return <i key={index} className={filled ? 'filled' : ''} />;
      })}
    </div>
  );
}

export default function BookingFlow({ route, stops, onClose }) {
  const [step, setStep] = useState('journey');
  const [sourceId, setSourceId] = useState(stops[0]?.id || '');
  const [destinationId, setDestinationId] = useState(stops.at(-1)?.id || '');
  const [departureAt, setDepartureAt] = useState('');
  const [passengers, setPassengers] = useState(1);
  const [upiId, setUpiId] = useState('');
  const [paymentResult, setPaymentResult] = useState('success');
  const [paymentError, setPaymentError] = useState('');
  const [processing, setProcessing] = useState(false);
  const [ticket, setTicket] = useState(null);
  const [currentTime, setCurrentTime] = useState(0);
  const [minimumDeparture, setMinimumDeparture] = useState('');

  useEffect(() => {
    const updateClock = () => {
      const timestamp = Date.now();
      setCurrentTime(timestamp);
      setMinimumDeparture(localDateTime(timestamp));
      return timestamp;
    };
    const firstUpdate = window.setTimeout(() => setDepartureAt(localDateTime(updateClock() + 10 * 60 * 1000)), 0);
    const interval = window.setInterval(updateClock, 30000);
    return () => {
      window.clearTimeout(firstUpdate);
      window.clearInterval(interval);
    };
  }, []);

  const sourceIndex = stops.findIndex((stop) => String(stop.id) === String(sourceId));
  const destinationIndex = stops.findIndex((stop) => String(stop.id) === String(destinationId));
  const validJourney = sourceIndex >= 0 && destinationIndex > sourceIndex;
  const validDeparture = departureAt && (currentTime === 0 || new Date(departureAt).getTime() >= currentTime);
  const fare = useMemo(() => Math.max(10, (destinationIndex - sourceIndex) * 5) * passengers, [destinationIndex, passengers, sourceIndex]);
  const source = stops[sourceIndex];
  const destination = stops[destinationIndex];
  const validUpi = /^[\w.-]{2,256}@[A-Za-z][\w.-]{1,63}$/.test(upiId.trim());

  async function pay() {
    setPaymentError('');
    if (!validUpi) {
      setPaymentError('Enter a valid UPI ID, such as name@bank.');
      return;
    }
    setProcessing(true);
    await new Promise((resolve) => window.setTimeout(resolve, 900));
    if (paymentResult === 'failure') {
      setProcessing(false);
      setPaymentError('The demo payment was declined. Choose another demo option or try again.');
      return;
    }

    const confirmedTicket = {
      bookingId: bookingCode(),
      routeId: route.id,
      routeNumber: route.routeNumber,
      routeName: `${route.source} → ${route.destination}`,
      source: source.name,
      destination: destination.name,
      departureAt,
      passengers,
      fare,
      upiId: upiId.trim(),
      bookedAt: new Date().toISOString()
    };
    try {
      const current = JSON.parse(window.localStorage.getItem('transitgo-bookings') || '[]');
      if (!Array.isArray(current)) throw new Error('Booking history is not in the expected format.');
      window.localStorage.setItem('transitgo-bookings', JSON.stringify([confirmedTicket, ...current]));
      window.dispatchEvent(new Event('transitgo-bookings-updated'));
      setTicket(confirmedTicket);
      setStep('ticket');
    } catch (error) {
      console.error('Could not save booking:', error);
      setPaymentError('Payment succeeded in demo mode, but booking history could not be saved in this browser.');
    } finally {
      setProcessing(false);
    }
  }

  return (
    <div className="booking-modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget && !processing) onClose(); }}>
      <section className="booking-modal" role="dialog" aria-modal="true" aria-labelledby="booking-title">
        <div className="booking-modal-header">
          <div>
            <span className="eyebrow">{step === 'ticket' ? 'BOOKING COMPLETE' : 'TICKET BOOKING · DEMO'}</span>
            <h2 id="booking-title">{step === 'ticket' ? 'Your ticket is ready' : 'Plan your ride'}</h2>
          </div>
          <button type="button" className="modal-close-button" onClick={onClose} aria-label="Close booking" disabled={processing}>×</button>
        </div>
        {step !== 'ticket' && <div className="booking-progress"><span className={step === 'journey' ? 'active' : 'complete'}>Journey</span><i /><span className={step === 'review' ? 'active' : step === 'payment' ? 'complete' : ''}>Review</span><i /><span className={step === 'payment' ? 'active' : ''}>Payment</span></div>}

        {step === 'journey' && (
          <div className="booking-form-content">
            <div className="booking-route-banner"><span>BUS {route.routeNumber}</span><strong>{route.source} <i>→</i> {route.destination}</strong></div>
            <label className="booking-field">Boarding stop
              <select value={sourceId} onChange={(event) => setSourceId(event.target.value)}>
                {stops.map((stop, index) => <option key={stop.id} value={stop.id} disabled={index >= destinationIndex}>{stop.name}</option>)}
              </select>
            </label>
            <label className="booking-field">Destination
              <select value={destinationId} onChange={(event) => setDestinationId(event.target.value)}>
                {stops.map((stop, index) => <option key={stop.id} value={stop.id} disabled={index <= sourceIndex}>{stop.name}</option>)}
              </select>
            </label>
            <div className="booking-fields-row">
              <label className="booking-field">Travel date &amp; time
                <input type="datetime-local" min={minimumDeparture} value={departureAt} onChange={(event) => setDepartureAt(event.target.value)} />
              </label>
              <label className="booking-field">Passengers
                <select value={passengers} onChange={(event) => setPassengers(Number(event.target.value))}>
                  {[1, 2, 3, 4, 5, 6].map((count) => <option key={count} value={count}>{count} {count === 1 ? 'passenger' : 'passengers'}</option>)}
                </select>
              </label>
            </div>
            {!validJourney && <p className="booking-validation">Choose a destination after your boarding stop.</p>}
            <div className="fare-preview"><span>Estimated demo fare</span><strong>₹{fare}</strong></div>
            {!validDeparture && departureAt && <p className="booking-validation">Choose a departure time that is not in the past.</p>}
            <button type="button" className="booking-primary-button" disabled={!validJourney || !validDeparture} onClick={() => setStep('review')}>Review ticket <span>→</span></button>
            <p className="demo-disclaimer">Demo booking only. Fare is an estimate and no real ticket or payment is issued.</p>
          </div>
        )}

        {step === 'review' && (
          <div className="booking-form-content">
            <div className="ticket-summary-card">
              <div className="summary-route-line"><span className="route-number-chip">BUS {route.routeNumber}</span><span>{route.direction || 'Scheduled service'}</span></div>
              <div className="summary-stops"><div><small>FROM</small><strong>{source?.name}</strong></div><span>→</span><div><small>TO</small><strong>{destination?.name}</strong></div></div>
              <div className="summary-detail-row"><span>Date &amp; time</span><strong>{new Date(departureAt).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })}</strong></div>
              <div className="summary-detail-row"><span>Passengers</span><strong>{passengers}</strong></div>
              <div className="summary-detail-row total"><span>Estimated total</span><strong>₹{fare}</strong></div>
            </div>
            <div className="booking-action-row"><button type="button" className="booking-secondary-button" onClick={() => setStep('journey')}>Back</button><button type="button" className="booking-primary-button" onClick={() => setStep('payment')}>Continue to payment <span>→</span></button></div>
            <p className="demo-disclaimer">Review your trip details before continuing to mock UPI payment.</p>
          </div>
        )}

        {step === 'payment' && (
          <div className="booking-form-content">
            <div className="mock-payment-heading"><span className="upi-mark">UPI</span><div><strong>Mock UPI payment</strong><small>Secure demo · no money will be charged</small></div></div>
            <label className="booking-field">UPI ID
              <input type="text" autoComplete="off" placeholder="name@bank" value={upiId} onChange={(event) => setUpiId(event.target.value)} />
            </label>
            <div className="mock-upi-options"><span>Quick demo IDs</span><button type="button" onClick={() => setUpiId('demo@upi')}>demo@upi</button><button type="button" onClick={() => setUpiId('transitgo@demo')}>transitgo@demo</button></div>
            <fieldset className="payment-outcome-choice">
              <legend>Demo response</legend>
              <label><input type="radio" name="paymentResult" value="success" checked={paymentResult === 'success'} onChange={() => setPaymentResult('success')} /> Approve payment</label>
              <label><input type="radio" name="paymentResult" value="failure" checked={paymentResult === 'failure'} onChange={() => setPaymentResult('failure')} /> Simulate decline</label>
            </fieldset>
            {paymentError && <p className="payment-error" role="alert">{paymentError}</p>}
            <div className="payment-total"><span>Payable amount</span><strong>₹{fare}</strong></div>
            <div className="booking-action-row"><button type="button" className="booking-secondary-button" disabled={processing} onClick={() => setStep('review')}>Back</button><button type="button" className="booking-primary-button" disabled={processing} onClick={pay}>{processing ? 'Processing…' : `Pay ₹${fare} · Demo`} {!processing && <span>→</span>}</button></div>
            <p className="demo-disclaimer">This is a simulated payment. No real UPI request or gateway is used.</p>
          </div>
        )}

        {step === 'ticket' && ticket && (
          <div className="generated-ticket">
            <div className="ticket-success"><span>✓</span><div><strong>Payment successful</strong><small>Mock UPI payment · Ticket generated</small></div></div>
            <div className="digital-ticket">
              <div className="digital-ticket-top"><div><span>TRANSITGO · DIGITAL TICKET</span><strong>Bus {ticket.routeNumber}</strong></div><TicketPattern value={ticket.bookingId} /></div>
              <div className="ticket-pnr"><small>BOOKING ID / PNR</small><strong>{ticket.bookingId}</strong></div>
              <div className="ticket-trip"><div><small>BOARDING</small><strong>{ticket.source}</strong></div><span>→</span><div><small>DESTINATION</small><strong>{ticket.destination}</strong></div></div>
              <div className="ticket-route-name">{ticket.routeName}</div>
              <div className="ticket-details-grid"><div><small>DATE &amp; TIME</small><strong>{new Date(ticket.departureAt).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })}</strong></div><div><small>PASSENGERS</small><strong>{ticket.passengers}</strong></div><div><small>FARE PAID · DEMO</small><strong>₹{ticket.fare}</strong></div><div><small>PAYMENT MODE</small><strong>Mock UPI</strong></div></div>
            </div>
            <button type="button" className="booking-primary-button" onClick={onClose}>Done <span>✓</span></button>
          </div>
        )}
      </section>
    </div>
  );
}
