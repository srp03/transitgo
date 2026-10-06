package com.transitgo.backend.repository

import com.transitgo.backend.entity.Stop
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param

interface StopRepository : JpaRepository<Stop, Long> {
    fun findByGtfsStopId(gtfsStopId: String): Stop?
    fun existsByGtfsStopId(gtfsStopId: String): Boolean

    @Query("SELECT s FROM Stop s WHERE LOWER(s.name) LIKE LOWER(CONCAT('%', :query, '%'))")
    fun searchStopsByName(@Param("query") query: String): List<Stop>
}
