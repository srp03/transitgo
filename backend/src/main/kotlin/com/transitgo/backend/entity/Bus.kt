package com.transitgo.backend.entity

import jakarta.persistence.*

@Entity
@Table(name = "buses")
class Bus(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,
    var vehicleNumber: String = "",

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "route_id")
    var route: Route? = null,

    var vehicleType: String = "Electric AC", // Electric AC, CNG Non-AC, Local Rake
    var capacity: Int = 40,
    var occupancyStatus: String = "Moderate", // Low, Moderate, High
    var status: String = "On time",           // On time, Delayed
    var active: Boolean = true
)
