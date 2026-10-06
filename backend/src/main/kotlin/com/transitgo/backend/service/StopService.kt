package com.transitgo.backend.service

import com.transitgo.backend.dto.RouteSummaryDto
import com.transitgo.backend.dto.StopDto
import com.transitgo.backend.dto.StopWithRoutesDto
import com.transitgo.backend.entity.Stop
import com.transitgo.backend.repository.RouteStopRepository
import com.transitgo.backend.repository.StopRepository
import org.springframework.stereotype.Service
import kotlin.math.*

@Service
class StopService(
    private val stopRepository: StopRepository,
    private val routeStopRepository: RouteStopRepository
) {
    fun getAllStops(): List<StopDto> {
        return stopRepository.findAll().map { toStopDto(it) }
    }

    fun getStopById(id: Long): StopWithRoutesDto? {
        val stop = stopRepository.findById(id).orElse(null) ?: return null
        val routes = getRoutesForStop(id)
        return StopWithRoutesDto(
            id = stop.id!!,
            gtfsStopId = stop.gtfsStopId,
            name = stop.name,
            latitude = stop.latitude,
            longitude = stop.longitude,
            routes = routes
        )
    }

    fun getRoutesForStop(stopId: Long): List<RouteSummaryDto> {
        val routeStops = routeStopRepository.findByStopId(stopId)
        val distinctRoutes = routeStops.mapNotNull { it.route }.distinctBy { it.id }
        return distinctRoutes.map { r ->
            RouteSummaryDto(
                id = r.id!!,
                gtfsRouteId = r.gtfsRouteId,
                routeNumber = r.routeNumber,
                routeName = r.routeName,
                source = r.source,
                destination = r.destination,
                direction = r.direction
            )
        }
    }

    fun getNearbyStops(lat: Double, lng: Double, radiusKm: Double = 5.0): List<StopDto> {
        val stops = stopRepository.findAll()
        val nearby = stops.mapNotNull { stop ->
            val dist = haversineDistance(lat, lng, stop.latitude, stop.longitude)
            if (dist <= radiusKm) {
                StopDto(
                    id = stop.id!!,
                    gtfsStopId = stop.gtfsStopId,
                    name = stop.name,
                    latitude = stop.latitude,
                    longitude = stop.longitude,
                    distanceKm = (dist * 100).roundToInt() / 100.0
                )
            } else null
        }
        return nearby.sortedBy { it.distanceKm }
    }

    fun searchStopsByName(query: String): List<StopDto> {
        return stopRepository.searchStopsByName(query).map { toStopDto(it) }
    }

    private fun toStopDto(stop: Stop): StopDto {
        return StopDto(
            id = stop.id!!,
            gtfsStopId = stop.gtfsStopId,
            name = stop.name,
            latitude = stop.latitude,
            longitude = stop.longitude
        )
    }

    private fun haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val r = 6371.0 // Earth radius in km
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return r * c
    }
}
