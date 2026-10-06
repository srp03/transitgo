package com.transitgo.backend.repository

import com.transitgo.backend.entity.Route
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param

interface RouteRepository : JpaRepository<Route, Long> {
    fun findByGtfsRouteId(gtfsRouteId: String): Route?
    fun existsByGtfsRouteId(gtfsRouteId: String): Boolean

    fun findByAgencyId(agencyId: String): List<Route>

    @Query("SELECT r FROM Route r WHERE LOWER(r.source) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(r.destination) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(r.routeNumber) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(r.routeName) LIKE LOWER(CONCAT('%', :query, '%'))")
    fun searchRoutes(@Param("query") query: String): List<Route>
}