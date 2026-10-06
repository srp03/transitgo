package com.transitgo.backend.entity

import jakarta.persistence.*

@Entity
@Table(
    name = "trips",
    indexes = [
        Index(name = "idx_trips_gtfs_id", columnList = "gtfsTripId"),
        Index(name = "idx_trips_route_id", columnList = "route_id")
    ]
)
class Trip(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @Column(nullable = false, unique = true)
    var gtfsTripId: String = "",

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "route_id")
    var route: Route? = null,

    var serviceId: String = "",
    var tripHeadsign: String? = null,
    var directionId: Int? = null
)
