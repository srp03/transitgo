package com.transitgo.backend.service

import com.transitgo.backend.entity.BusLocation
import com.transitgo.backend.repository.BusLocationRepository
import com.transitgo.backend.repository.BusRepository
import com.transitgo.backend.repository.RouteStopRepository
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Service
import kotlin.math.*

@Service
class MockGpsEngineService(
    private val busRepository: BusRepository,
    private val routeStopRepository: RouteStopRepository,
    private val busLocationRepository: BusLocationRepository
) {
    // Internal state mapping busId -> progress state (current stop index, interpolation progress 0.0..1.0)
    private val busProgressMap = mutableMapOf<Long, Pair<Int, Double>>()

    @Scheduled(fixedRate = 3000)
    fun updateMockBusLocations() {
        val buses = busRepository.findAll().filter { it.active && it.route != null }

        buses.forEach { bus ->
            val route = bus.route ?: return@forEach
            val routeStops = routeStopRepository.findByRouteIdOrderByStopSequenceAsc(route.id!!)
            if (routeStops.size < 2) return@forEach

            val busId = bus.id!!
            val (currentIndex, rawProgress) = busProgressMap.getOrDefault(busId, Pair(0, 0.0))

            // Step progress by ~5% per tick
            var progress = rawProgress + 0.06
            var idx = currentIndex

            if (progress >= 1.0) {
                progress = 0.0
                idx += 1
                if (idx >= routeStops.size - 1) {
                    idx = 0 // Loop route back from starting point
                }
            }

            busProgressMap[busId] = Pair(idx, progress)

            val currentStop = routeStops[idx].stop ?: return@forEach
            val nextStop = routeStops[idx + 1].stop ?: return@forEach

            // Interpolate latitude and longitude
            val lat = currentStop.latitude + (nextStop.latitude - currentStop.latitude) * progress
            val lng = currentStop.longitude + (nextStop.longitude - currentStop.longitude) * progress

            val heading = calculateHeading(currentStop.latitude, currentStop.longitude, nextStop.latitude, nextStop.longitude)
            val speed = 25.0 + (busId % 15) // Speed between 25-40 km/h

            // Remaining stops calculation for ETA
            val remainingStopsCount = (routeStops.size - 1) - idx - progress
            val etaMinutes = max(1, (remainingStopsCount * 4.5).roundToInt())

            val existingLocation = busLocationRepository.findByBusId(busId)
            if (existingLocation != null) {
                existingLocation.latitude = lat
                existingLocation.longitude = lng
                existingLocation.speed = speed
                existingLocation.heading = heading
                existingLocation.timestamp = System.currentTimeMillis()
                existingLocation.currentStopName = currentStop.name
                existingLocation.nextStopName = nextStop.name
                existingLocation.etaMinutes = etaMinutes
                existingLocation.status = bus.status
                busLocationRepository.save(existingLocation)
            } else {
                val newLocation = BusLocation(
                    busId = busId,
                    routeId = route.id!!,
                    latitude = lat,
                    longitude = lng,
                    speed = speed,
                    heading = heading,
                    timestamp = System.currentTimeMillis(),
                    currentStopName = currentStop.name,
                    nextStopName = nextStop.name,
                    etaMinutes = etaMinutes,
                    status = bus.status
                )
                busLocationRepository.save(newLocation)
            }
        }
    }

    private fun calculateHeading(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val dLon = Math.toRadians(lon2 - lon1)
        val rLat1 = Math.toRadians(lat1)
        val rLat2 = Math.toRadians(lat2)

        val y = sin(dLon) * cos(rLat2)
        val x = cos(rLat1) * sin(rLat2) - sin(rLat1) * cos(rLat2) * cos(dLon)

        var brng = Math.toDegrees(atan2(y, x))
        return (brng + 360) % 360
    }
}
