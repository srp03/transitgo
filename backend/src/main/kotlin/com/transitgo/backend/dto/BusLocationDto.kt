package com.transitgo.backend.dto

data class BusLocationDto(
    val busId: Long,
    val vehicleNumber: String,
    val routeId: Long,
    val routeNumber: String,
    val source: String,
    val destination: String,
    val transportType: String = "BUS",
    val latitude: Double,
    val longitude: Double,
    val speed: Double,
    val heading: Double,
    val timestamp: Long,
    val currentStopName: String,
    val nextStopName: String,
    val etaMinutes: Int,
    val status: String,
    val vehicleType: String = "TMT Standard Bus",
    val capacity: Int = 40,
    val occupancyStatus: String = "Moderate",
    val isMock: Boolean = true,
    val dataLabel: String = "Demo / Simulated"
)
