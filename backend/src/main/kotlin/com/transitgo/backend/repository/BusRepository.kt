package com.transitgo.backend.repository

import com.transitgo.backend.entity.Bus
import org.springframework.data.jpa.repository.JpaRepository

interface BusRepository : JpaRepository<Bus, Long> {
    fun findByRouteId(routeId: Long): List<Bus>
    fun findByRoute_Id(routeId: Long): List<Bus>
    fun existsByVehicleNumber(vehicleNumber: String): Boolean
}
