package com.transitgo.backend.dto

import com.transitgo.backend.entity.Route

data class RouteSearchResultDto(
    val id: Long,
    val routeNumber: String,
    val source: String,
    val destination: String,
    val transportType: String,
    val estimatedDuration: Int,
    val fare: Double,
    val frequency: String,
    val firstBusTime: String,
    val lastBusTime: String,
    val stopsCount: Int,
    val nextBusEtaMinutes: Int,
    val nextBusTime: String,
    val activeBusesCount: Int,
    val stops: List<StopDto> = emptyList()
)
