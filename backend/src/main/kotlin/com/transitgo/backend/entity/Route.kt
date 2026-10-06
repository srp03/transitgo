package com.transitgo.backend.entity

import jakarta.persistence.*

@Entity
@Table(
    name = "routes",
    indexes = [
        Index(name = "idx_routes_gtfs_id", columnList = "gtfsRouteId"),
        Index(name = "idx_routes_agency", columnList = "agencyId"),
        Index(name = "idx_routes_number", columnList = "routeNumber")
    ]
)
class Route(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @Column(nullable = false, unique = true)
    var gtfsRouteId: String = "",

    var agencyId: String = "TMT",
    var routeNumber: String = "",       // GTFS route_short_name (e.g. "10", "10AC")
    var routeName: String = "",         // GTFS route_long_name
    var source: String = "",
    var destination: String = "",
    var direction: String = "",         // "UP", "DOWN"
    var routeType: Int = 3,             // 3 = Bus
    var active: Boolean = true
)