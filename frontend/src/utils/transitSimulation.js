function timeToMinutes(value) {
  if (!value) return null;
  const match = value.trim().match(/^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$/i);
  if (!match) return null;
  let hours = Number(match[1]);
  const minutes = Number(match[2]);
  if (match[3]) {
    hours %= 12;
    if (match[3].toUpperCase() === 'PM') hours += 12;
  }
  return hours * 60 + minutes;
}

export function formatClock(minutes) {
  const normalized = ((Math.round(minutes) % 1440) + 1440) % 1440;
  const hours = Math.floor(normalized / 60);
  return `${String(hours % 12 || 12).padStart(2, '0')}:${String(normalized % 60).padStart(2, '0')} ${hours < 12 ? 'AM' : 'PM'}`;
}

function formatDateClock(date) {
  return formatClock(date.getHours() * 60 + date.getMinutes());
}

function getLocalDayOffset(date, referenceDate) {
  const day = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  const referenceDay = new Date(referenceDate.getFullYear(), referenceDate.getMonth(), referenceDate.getDate());
  return Math.round((day - referenceDay) / 86400000);
}

function getStopInterval(previousStop, stop) {
  const previousTime = timeToMinutes(previousStop.departureTime) ?? timeToMinutes(previousStop.arrivalTime);
  const stopTime = timeToMinutes(stop.arrivalTime) ?? timeToMinutes(stop.departureTime);
  if (previousTime === null || stopTime === null) return 2;
  const difference = stopTime - previousTime;
  const interval = difference > 0 ? difference : difference + 1440;
  return Math.max(1, Math.min(3, interval));
}

export function createSimulatedTimetable(routeStops, selectedAt) {
  if (routeStops.length === 0) return { stops: [], schedules: [] };

  const firstDeparture = new Date(selectedAt);
  firstDeparture.setMinutes(firstDeparture.getMinutes() + 14, 0, 0);
  const firstDepartureTimestamp = firstDeparture.getTime();

  let stopOffsetMinutes = 0;
  const stops = routeStops.map((stop, index) => {
    if (index > 0) {
      stopOffsetMinutes += getStopInterval(routeStops[index - 1], stop);
    }
    const stopTime = new Date(firstDepartureTimestamp + stopOffsetMinutes * 60000);
    const timeLabel = `${getLocalDayOffset(stopTime, selectedAt) ? 'Tomorrow · ' : 'Today · '}${formatDateClock(stopTime)}`;
    return {
      ...stop,
      arrivalTime: formatDateClock(stopTime),
      departureTime: formatDateClock(stopTime),
      simulatedOffsetMinutes: stopOffsetMinutes,
      simulatedDayOffset: getLocalDayOffset(stopTime, selectedAt),
      simulatedTimeLabel: timeLabel
    };
  });

  const schedules = [];
  const scheduleHorizon = firstDepartureTimestamp + 48 * 60 * 60000;
  for (let timestamp = firstDepartureTimestamp, index = 0; timestamp <= scheduleHorizon; timestamp += 15 * 60000, index += 1) {
    const departureDate = new Date(timestamp);
    schedules.push({
      id: `simulated-${timestamp}`,
      departureTimestamp: timestamp,
      departureTime: formatDateClock(departureDate),
      dayOffset: getLocalDayOffset(departureDate, selectedAt)
    });
  }

  return { stops, schedules };
}

export function getUpcomingDepartures(schedules, now) {
  const todayMinutes = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60;
  return schedules
    .map((schedule) => {
      if (Number.isFinite(schedule.departureTimestamp)) {
        const minutesFromNow = Math.max(0, (schedule.departureTimestamp - now.getTime()) / 60000);
        return {
          schedule,
          minutesFromNow,
          dayOffset: getLocalDayOffset(new Date(schedule.departureTimestamp), now),
          time: new Date(schedule.departureTimestamp).getHours() * 60 + new Date(schedule.departureTimestamp).getMinutes()
        };
      }
      const time = timeToMinutes(schedule.departureTime);
      if (time === null) return null;
      const minutesFromNow = time >= todayMinutes ? time - todayMinutes : time + 1440 - todayMinutes;
      return {
        schedule,
        minutesFromNow,
        dayOffset: Math.floor((todayMinutes + minutesFromNow) / 1440),
        time
      };
    })
    .filter(Boolean)
    .sort((first, second) => first.minutesFromNow - second.minutesFromNow);
}

export function getSimulation(routeStops, schedules, now) {
  if (routeStops.some((stop) => Number.isFinite(stop.simulatedOffsetMinutes)) &&
      schedules.some((schedule) => Number.isFinite(schedule.departureTimestamp))) {
    const nowTimestamp = now.getTime();
    const stopOffsets = routeStops.map((stop) => stop.simulatedOffsetMinutes);
    const routeDuration = Math.max(1, stopOffsets[stopOffsets.length - 1] || 1);
    const departures = schedules
      .map((schedule) => schedule.departureTimestamp)
      .sort((a, b) => a - b);
    let departure = departures.find((timestamp) => timestamp >= nowTimestamp);
    let tripActive = false;
    const activeDeparture = [...departures].reverse().find((timestamp) =>
      nowTimestamp >= timestamp && nowTimestamp <= timestamp + routeDuration * 60000
    );
    if (activeDeparture !== undefined) {
      departure = activeDeparture;
      tripActive = true;
    }
    if (departure === undefined) departure = nowTimestamp;

    const elapsedMinutes = tripActive ? (nowTimestamp - departure) / 60000 : 0;
    let segment = 0;
    let progress = 0;
    let nextStopIndex = Math.min(1, routeStops.length - 1);
    if (tripActive) {
      for (let index = 0; index < stopOffsets.length - 1; index += 1) {
        if (elapsedMinutes <= stopOffsets[index + 1]) {
          segment = index;
          const duration = Math.max(1, stopOffsets[index + 1] - stopOffsets[index]);
          progress = Math.max(0, Math.min(1, (elapsedMinutes - stopOffsets[index]) / duration));
          nextStopIndex = index + 1;
          break;
        }
        segment = index + 1;
        nextStopIndex = Math.min(segment + 1, routeStops.length - 1);
      }
    }

    const from = routeStops[segment];
    const to = routeStops[Math.min(segment + 1, routeStops.length - 1)] || from;
    if (!from || !to) return null;
    const etaMinutes = tripActive
      ? Math.max(0, Math.ceil(stopOffsets[nextStopIndex] - elapsedMinutes))
      : Math.max(0, Math.ceil((departure - nowTimestamp) / 60000));
    const departureDate = new Date(departure);

    return {
      latitude: Number(from.latitude) + (Number(to.latitude) - Number(from.latitude)) * progress,
      longitude: Number(from.longitude) + (Number(to.longitude) - Number(from.longitude)) * progress,
      currentStopName: from.name,
      nextStopName: tripActive ? (routeStops[nextStopIndex]?.name || from.name) : (routeStops[0]?.name || from.name),
      etaMinutes,
      scheduledTime: formatDateClock(departureDate),
      scheduledDayOffset: getLocalDayOffset(departureDate, now),
      status: !tripActive ? 'Next scheduled trip' : etaMinutes <= 2 ? 'Approaching stop' : 'On time',
      active: tripActive
    };
  }

  const todayMinutes = now.getHours() * 60 + now.getMinutes() + now.getSeconds() / 60;
  const stopTimes = routeStops.map((stop) =>
    timeToMinutes(stop.departureTime) ?? timeToMinutes(stop.arrivalTime)
  );
  const firstKnown = stopTimes.find((time) => time !== null);
  const lastKnown = [...stopTimes].reverse().find((time) => time !== null);
  const routeDuration = firstKnown !== undefined && lastKnown !== undefined
    ? Math.max(1, lastKnown - firstKnown)
    : Math.max(5, (routeStops.length - 1) * 3);
  const departures = schedules
    .map((schedule) => timeToMinutes(schedule.departureTime))
    .filter((time) => time !== null)
    .sort((a, b) => a - b);

  let departure = departures.find((time) => time >= todayMinutes);
  let tripActive = false;
  if (departures.some((time) => todayMinutes >= time && todayMinutes <= time + routeDuration)) {
    departure = [...departures].reverse().find((time) => todayMinutes >= time && todayMinutes <= time + routeDuration);
    tripActive = true;
  } else if (departure === undefined && departures.length > 0) {
    departure = departures[0] + 1440;
  }

  if (departure === undefined && firstKnown !== undefined) {
    departure = firstKnown >= todayMinutes ? firstKnown : firstKnown + 1440;
    tripActive = todayMinutes >= firstKnown && todayMinutes <= lastKnown;
  }
  if (departure === undefined) departure = todayMinutes;

  const departureDayOffset = Math.floor(departure / 1440);
  const referenceBase = firstKnown ?? departure;
  const positionTime = tripActive ? todayMinutes - departure + referenceBase : referenceBase;
  let segment = 0;
  let progress = 0;
  let nextStopIndex = Math.min(1, routeStops.length - 1);

  if (tripActive) {
    const timeline = stopTimes.map((time, index) => ({
      index,
      time: time === null ? referenceBase + (routeDuration * index) / Math.max(1, routeStops.length - 1) : time
    }));
    for (let index = 0; index < timeline.length - 1; index += 1) {
      if (positionTime >= timeline[index].time && positionTime <= timeline[index + 1].time) {
        segment = index;
        const duration = Math.max(1, timeline[index + 1].time - timeline[index].time);
        progress = Math.max(0, Math.min(1, (positionTime - timeline[index].time) / duration));
        nextStopIndex = index + 1;
        break;
      }
      if (positionTime > timeline[index + 1].time) {
        segment = Math.min(index + 1, routeStops.length - 1);
        nextStopIndex = Math.min(segment + 1, routeStops.length - 1);
      }
    }
  }

  const from = routeStops[segment];
  const to = routeStops[Math.min(segment + 1, routeStops.length - 1)] || from;
  if (!from || !to) return null;
  const nextTime = stopTimes[nextStopIndex] ?? (referenceBase + routeDuration * nextStopIndex / Math.max(1, routeStops.length - 1));
  const etaMinutes = tripActive ? Math.max(0, Math.ceil(nextTime - positionTime)) : Math.max(0, Math.ceil(departure - todayMinutes));

  return {
    latitude: from.latitude + (to.latitude - from.latitude) * progress,
    longitude: from.longitude + (to.longitude - from.longitude) * progress,
    currentStopName: from.name,
    nextStopName: tripActive ? (routeStops[nextStopIndex]?.name || from.name) : (routeStops[0]?.name || from.name),
    etaMinutes,
    scheduledTime: formatClock(departure),
    scheduledDayOffset: departureDayOffset,
    status: !tripActive ? 'Next scheduled trip' : etaMinutes <= 2 ? 'Approaching stop' : 'On time',
    active: tripActive
  };
}
