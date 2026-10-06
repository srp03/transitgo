package com.transitgo.backend.service

import com.transitgo.backend.dto.BusLocationDto
import com.transitgo.backend.entity.Bus
import com.transitgo.backend.repository.BusLocationRepository
import com.transitgo.backend.repository.BusRepository
import org.springframework.stereotype.Service

@Service
class BusService(
    private val busRepository: BusRepository,
    private val busLocationRepository: BusLocationRepository
) {
    fun getAllBuses(): List<Bus> = busRepository.findAll()

    fun getBusById(id: Long): Bus? = busRepository.findById(id).orElse(null)

    fun getBusesByRoute(routeId: Long): List<Bus> = busRepository.findByRouteId(routeId)

    fun getLiveBusLocations(): List<BusLocationDto> {
        val buses = busRepository.findAll().filter { it.active && it.route != null }
        return buses.mapNotNull { bus ->
            val location = busLocationRepository.findByBusId(bus.id!!) ?: return@mapNotNull null
            val route = bus.route!!
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

    fun getBusLocation(busId: Long): BusLocationDto? {
        val bus = busRepository.findById(busId).orElse(null) ?: return null
        val location = busLocationRepository.findByBusId(busId) ?: return null
        val route = bus.route ?: return null

        return BusLocationDto(
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
