package com.transitgo.backend.repository

import com.transitgo.backend.entity.RouteStop
import org.springframework.data.jpa.repository.JpaRepository

interface RouteStopRepository : JpaRepository<RouteStop, Long> {
    fun findByRouteIdOrderByStopSequenceAsc(routeId: Long): List<RouteStop>
    fun findByStopId(stopId: Long): List<RouteStop>
}
