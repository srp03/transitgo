package com.transitgo.backend.dto

data class StopDto(
    val id: Long,
    val gtfsStopId: String,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val sequence: Int? = null,
    val arrivalTime: String? = null,
    val departureTime: String? = null,
    val distanceKm: Double? = null
)

data class StopWithRoutesDto(
    val id: Long,
    val gtfsStopId: String,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val distanceKm: Double? = null,
    val routes: List<RouteSummaryDto> = emptyList()
)
