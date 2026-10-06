package com.transitgo.backend.service

import com.transitgo.backend.dto.BusLocationDto
import com.transitgo.backend.dto.RouteDto
import com.transitgo.backend.dto.RouteSummaryDto
import com.transitgo.backend.dto.ScheduleDto
import com.transitgo.backend.dto.StopDto
import com.transitgo.backend.entity.Route
import com.transitgo.backend.repository.BusLocationRepository
import com.transitgo.backend.repository.BusRepository
import com.transitgo.backend.repository.RouteRepository
import com.transitgo.backend.repository.RouteStopRepository
import com.transitgo.backend.repository.StopTimeRepository
import com.transitgo.backend.repository.TripRepository
import org.springframework.stereotype.Service

@Service
class RouteService(
    private val routeRepository: RouteRepository,
    private val routeStopRepository: RouteStopRepository,
    private val tripRepository: TripRepository,
    private val stopTimeRepository: StopTimeRepository,
    private val busRepository: BusRepository,
    private val busLocationRepository: BusLocationRepository
) {
    fun getAllRoutes(): List<RouteDto> {
        val routes = routeRepository.findByAgencyId("TMT")
        return routes.map { toRouteDto(it) }
    }

    fun getRouteById(id: Long): RouteDto? {
        val route = routeRepository.findById(id).orElse(null) ?: return null
        return toRouteDto(route, includeStops = true)
    }

    fun searchRoutes(from: String?, to: String?): List<RouteDto> {
        val allTmtRoutes = routeRepository.findByAgencyId("TMT")

        if (from.isNullOrBlank() && to.isNullOrBlank()) {
            return allTmtRoutes.map { toRouteDto(it) }
        }

        val cleanFrom = from?.trim()?.lowercase() ?: ""
        val cleanTo = to?.trim()?.lowercase() ?: ""
        val routeNumberQuery = from
            ?.trim()
            ?.replace(Regex("^(bus|route)\\s*", RegexOption.IGNORE_CASE), "")
            ?.replace(Regex("\\s+"), "")
            ?.uppercase()
            .orEmpty()

        if (cleanTo.isBlank() && routeNumberQuery.matches(Regex("\\d+[A-Z]*"))) {
            return allTmtRoutes
                .filter { it.routeNumber.replace(Regex("\\s+"), "").uppercase().startsWith(routeNumberQuery) }
                .sortedWith(
                    compareBy<Route> {
                        if (it.routeNumber.replace(Regex("\\s+"), "").equals(routeNumberQuery, ignoreCase = true)) 0 else 1
                    }.thenBy { it.routeNumber }
                )
                .map { toRouteDto(it) }
        }

        val matchingRoutes = allTmtRoutes.filter { route ->
            if (cleanFrom.isNotBlank() && cleanTo.isNotBlank()) {
                // First try simple source→destination match (fast path for routes with empty stop lists)
                val sourceMatchFrom = route.source.lowercase().contains(cleanFrom) ||
                        route.routeName.lowercase().contains(cleanFrom)
                val destMatchTo = route.destination.lowercase().contains(cleanTo) ||
                        route.routeName.lowercase().contains(cleanTo)

                if (sourceMatchFrom && destMatchTo) return@filter true

                // Fall back to stop-sequence check for routes that have RouteStop entries
                val routeStops = routeStopRepository.findByRouteIdOrderByStopSequenceAsc(route.id!!)
                if (routeStops.isEmpty()) return@filter false

                val fromIndex = routeStops.indexOfFirst { rs ->
                    rs.stop?.name?.lowercase()?.contains(cleanFrom) == true
                }.let { idx ->
                    if (idx == -1 && route.source.lowercase().contains(cleanFrom)) 0 else idx
                }

                val toIndex = routeStops.indexOfLast { rs ->
                    rs.stop?.name?.lowercase()?.contains(cleanTo) == true
                }.let { idx ->
                    if (idx == -1 && route.destination.lowercase().contains(cleanTo)) routeStops.size - 1 else idx
                }

                fromIndex != -1 && toIndex != -1 && fromIndex < toIndex
            } else if (cleanFrom.isNotBlank()) {
                route.source.lowercase().contains(cleanFrom) ||
                        route.routeName.lowercase().contains(cleanFrom) ||
                        routeStopRepository.findByRouteIdOrderByStopSequenceAsc(route.id!!)
                            .any { it.stop?.name?.lowercase()?.contains(cleanFrom) == true }
            } else {
                route.destination.lowercase().contains(cleanTo) ||
                        route.routeName.lowercase().contains(cleanTo) ||
                        routeStopRepository.findByRouteIdOrderByStopSequenceAsc(route.id!!)
                            .any { it.stop?.name?.lowercase()?.contains(cleanTo) == true }
            }
        }

        return matchingRoutes.map { toRouteDto(it, includeStops = true) }
    }

    fun getRouteStops(routeId: Long): List<StopDto> {
        val routeStops = routeStopRepository.findByRouteIdOrderByStopSequenceAsc(routeId)
        return routeStops.map { rs ->
            StopDto(
                id = rs.stop?.id ?: 0L,
                gtfsStopId = rs.stop?.gtfsStopId ?: "",
                name = rs.stop?.name ?: "",
                latitude = rs.stop?.latitude ?: 0.0,
                longitude = rs.stop?.longitude ?: 0.0,
                sequence = rs.stopSequence,
                arrivalTime = rs.arrivalTime.ifBlank { null },
                departureTime = rs.departureTime.ifBlank { null }
            )
        }
    }

    fun getRouteSchedules(routeId: Long): List<ScheduleDto> {
        val trips = tripRepository.findByRouteId(routeId)
        val departureTimes = mutableListOf<String>()

        for (trip in trips) {
            val firstStopTime = stopTimeRepository.findByTripIdOrderByStopSequenceAsc(trip.id!!)
                .firstOrNull() ?: continue
            val dep = firstStopTime.departureTime.ifBlank { firstStopTime.arrivalTime }
            if (dep.isNotBlank()) departureTimes.add(dep)
        }

        // Sort departure times as HH:mm:ss strings
        val sorted = departureTimes
            .distinctBy { it }
            .sortedWith(Comparator { a, b ->
                val aVal = parseTimeToMinutes(a)
                val bVal = parseTimeToMinutes(b)
                aVal - bVal
            })

        return sorted.mapIndexed { i, time ->
            ScheduleDto(
                id = i.toLong(),
                tripIndex = i,
                departureTime = formatTime(time),
                arrivalTime = null,
                routeId = routeId
            )
        }
    }

    fun getRouteBuses(routeId: Long): List<BusLocationDto> {
        val buses = busRepository.findByRouteId(routeId).filter { it.active }
        return buses.mapNotNull { bus ->
            val location = busLocationRepository.findByBusId(bus.id!!) ?: return@mapNotNull null
            val route = bus.route ?: return@mapNotNull null
            BusLocationDto(
                busId = bus.id!!,
                vehicleNumber = bus.vehicleNumber,
                routeId = route.id!!,
                routeNumber = route.routeNumber,
                source = route.source,
                destination = route.destination,
                transportType = "BUS",
                latitude = location.latitude,
                longitude = location.longitude,
                speed = location.speed,
                heading = location.heading,
                timestamp = location.timestamp,
                currentStopName = location.currentStopName,
                nextStopName = location.nextStopName,
                etaMinutes = location.etaMinutes,
                status = bus.status,
                vehicleType = bus.vehicleType,
                capacity = bus.capacity,
                occupancyStatus = bus.occupancyStatus,
                isMock = true,
                dataLabel = "Demo / Simulated"
            )
        }
    }

    private fun parseTimeToMinutes(time: String): Int {
        return try {
            val parts = time.split(":")
            if (parts.size >= 2) parts[0].toInt() * 60 + parts[1].toInt() else 0
        } catch (e: Exception) { 0 }
    }

    private fun formatTime(time: String): String {
        return try {
            val parts = time.split(":")
            if (parts.size < 2) return time
            val hours = parts[0].toInt()
            val minutes = parts[1].toInt()
            val normalHours = hours % 24
            val amPm = if (normalHours < 12) "AM" else "PM"
            val displayHours = if (normalHours == 0) 12 else if (normalHours <= 12) normalHours else normalHours - 12
            "%02d:%02d %s".format(displayHours, minutes, amPm)
        } catch (e: Exception) { time }
    }

    private fun toRouteDto(route: Route, includeStops: Boolean = false): RouteDto {
        val stops = if (includeStops) getRouteStops(route.id!!) else emptyList()
        val stopsCount = if (includeStops) stops.size else routeStopRepository.findByRouteIdOrderByStopSequenceAsc(route.id!!).size

        return RouteDto(
            id = route.id!!,
            gtfsRouteId = route.gtfsRouteId,
            routeNumber = route.routeNumber,
            routeName = route.routeName,
            source = route.source,
            destination = route.destination,
            direction = route.direction,
            agencyId = route.agencyId,
            transportType = "BUS",
            stopsCount = stopsCount,
            fareInfo = "Fare information unavailable",
            stops = stops
        )
    }
}
