package com.transitgo.backend.entity

import jakarta.persistence.*

@Entity
@Table(name = "bookings")
class Booking(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @Column(nullable = false, unique = true)
    var bookingReference: String = "",

    @Column(nullable = false)
    var routeId: Long = 0L,

    @Column(nullable = false)
    var routeNumber: String = "",

    @Column(nullable = false)
    var routeName: String = "",

    @Column(nullable = false)
    var sourceStop: String = "",

    @Column(nullable = false)
    var destinationStop: String = "",

    @Column(nullable = false)
    var departureTime: String = "",

    @Column(nullable = false)
    var passengerCount: Int = 1,

    @Column(nullable = false)
    var fare: Double = 0.0,

    @Column(nullable = false)
    var status: String = "CONFIRMED", // CONFIRMED, CANCELLED, COMPLETED

    var paymentMethod: String = "UPI_DEMO",
    var paymentStatus: String = "PAID_DEMO",
    var upiId: String = "",

    @Column(nullable = false)
    var bookedAt: Long = System.currentTimeMillis(),

    @Column(length = 1000)
    var qrPayload: String = ""
)
