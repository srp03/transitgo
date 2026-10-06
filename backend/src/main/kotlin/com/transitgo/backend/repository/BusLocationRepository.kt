package com.transitgo.backend.repository

import com.transitgo.backend.entity.BusLocation
import org.springframework.data.jpa.repository.JpaRepository

interface BusLocationRepository : JpaRepository<BusLocation, Long> {
    fun findByBusId(busId: Long): BusLocation?
    fun findByRouteId(routeId: Long): List<BusLocation>
}
