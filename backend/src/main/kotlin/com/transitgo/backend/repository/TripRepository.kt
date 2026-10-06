package com.transitgo.backend.repository

import com.transitgo.backend.entity.Trip
import org.springframework.data.jpa.repository.JpaRepository

interface TripRepository : JpaRepository<Trip, Long> {
    fun findByGtfsTripId(gtfsTripId: String): Trip?
    fun findByRouteId(routeId: Long): List<Trip>
}
