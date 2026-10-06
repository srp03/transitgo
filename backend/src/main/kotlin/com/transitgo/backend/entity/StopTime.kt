package com.transitgo.backend.entity

import jakarta.persistence.*

@Entity
@Table(
    name = "stop_times",
    indexes = [
        Index(name = "idx_stop_times_trip_id", columnList = "trip_id"),
        Index(name = "idx_stop_times_stop_id", columnList = "stop_id"),
        Index(name = "idx_stop_times_seq", columnList = "trip_id,stopSequence")
    ]
)
class StopTime(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_id")
    var trip: Trip? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "stop_id")
    var stop: Stop? = null,

    var arrivalTime: String = "",
    var departureTime: String = "",
    var stopSequence: Int = 0
)
