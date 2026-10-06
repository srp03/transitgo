package com.transitgo.backend.repository

import com.transitgo.backend.entity.Schedule
import org.springframework.data.jpa.repository.JpaRepository

interface ScheduleRepository : JpaRepository<Schedule, Long> {
    fun findByRouteIdOrderByDepartureTimeAsc(routeId: Long): List<Schedule>
}
