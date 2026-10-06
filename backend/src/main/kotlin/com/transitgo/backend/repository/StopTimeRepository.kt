package com.transitgo.backend.repository

import com.transitgo.backend.entity.StopTime
import org.springframework.data.jpa.repository.JpaRepository

interface StopTimeRepository : JpaRepository<StopTime, Long> {
    fun findByTripIdOrderByStopSequenceAsc(tripId: Long): List<StopTime>
    fun findByStopId(stopId: Long): List<StopTime>
}
