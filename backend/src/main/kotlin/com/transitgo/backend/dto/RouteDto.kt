package com.transitgo.backend.dto

data class RouteDto(
    val id: Long,
    val gtfsRouteId: String,
    val routeNumber: String,
    val routeName: String,
    val source: String,
    val destination: String,
    val direction: String,
    val agencyId: String = "TMT",
    val transportType: String = "BUS",
    val stopsCount: Int = 0,
    val fareInfo: String = "Fare information unavailable",
    val stops: List<StopDto> = emptyList()
)

data class RouteSummaryDto(
    val id: Long,
    val gtfsRouteId: String,
    val routeNumber: String,
    val routeName: String,
    val source: String,
    val destination: String,
    val direction: String
)
