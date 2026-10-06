package com.transitgo.backend.entity

import jakarta.persistence.*

@Entity
@Table(
    name = "stops",
    indexes = [
        Index(name = "idx_stops_gtfs_id", columnList = "gtfsStopId"),
        Index(name = "idx_stops_name", columnList = "name"),
        Index(name = "idx_stops_lat_lng", columnList = "latitude,longitude")
    ]
)
class Stop(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @Column(nullable = false, unique = true)
    var gtfsStopId: String = "",

    var name: String = "",
    var latitude: Double = 0.0,
    var longitude: Double = 0.0
)
