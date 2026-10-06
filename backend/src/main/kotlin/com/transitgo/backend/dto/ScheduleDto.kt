package com.transitgo.backend.dto

data class ScheduleDto(
    val id: Long,
    val tripIndex: Int,
    val departureTime: String,
    val arrivalTime: String?,
    val routeId: Long
)
