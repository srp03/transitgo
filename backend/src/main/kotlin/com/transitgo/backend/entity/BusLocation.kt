package com.transitgo.backend.entity

import jakarta.persistence.*

@Entity
@Table(name = "bus_locations")
class BusLocation(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    var busId: Long = 0,
    var routeId: Long = 0,
    var latitude: Double = 0.0,
    var longitude: Double = 0.0,
    var speed: Double = 0.0,        // in km/h
    var heading: Double = 0.0,      // degrees
    var timestamp: Long = System.currentTimeMillis(),
    var currentStopName: String = "",
    var nextStopName: String = "",
    var etaMinutes: Int = 0,
    var status: String = "On time"
)
