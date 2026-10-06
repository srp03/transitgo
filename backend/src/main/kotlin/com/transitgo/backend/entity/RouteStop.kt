package com.transitgo.backend.entity

import jakarta.persistence.*

@Entity
@Table(
    name = "route_stops",
    indexes = [
        Index(name = "idx_route_stops_route_seq", columnList = "route_id,stopSequence"),
        Index(name = "idx_route_stops_stop_id", columnList = "stop_id")
    ]
)
class RouteStop(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "route_id")
    var route: Route? = null,

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "stop_id")
    var stop: Stop? = null,

    var stopSequence: Int = 0,
    var direction: String = "",
    var arrivalTime: String = "",
    var departureTime: String = ""
)
