package com.transitgo.backend.entity

import jakarta.persistence.*

@Entity
@Table(name = "schedules")
class Schedule(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "route_id")
    var route: Route? = null,

    var departureTime: String = "",
    var arrivalTime: String = "",
    var dayType: String = "ALL" // WEEKDAY, WEEKEND, ALL
)
