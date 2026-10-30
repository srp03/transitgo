package com.transitgo.backend.dto

data class BookingDto(
    val id: Long,
    val bookingReference: String,
    val routeId: Long,
    val routeNumber: String,
    val routeName: String,
    val sourceStop: String,
    val destinationStop: String,
    val departureTime: String,
    val passengerCount: Int,
    val fare: Double,
    val status: String,
    val paymentMethod: String,
    val paymentStatus: String,
    val upiId: String,
    val bookedAt: Long,
    val qrPayload: String,
    val isDemo: Boolean = true,
    val notice: String = "Demo ticket — Not an official TMT paper ticket"
)

data class CreateBookingRequest(
    val routeId: Long,
    val sourceStop: String,
    val destinationStop: String,
    val departureTime: String,
    val passengerCount: Int = 1,
    val fare: Double? = null,
    val upiId: String? = null
)
