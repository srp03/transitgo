package com.transitgo.backend.entity

import jakarta.persistence.*

@Entity
@Table(name = "users")
class User(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,
    var username: String = "",
    var email: String = "",
    var name: String = "",
    var role: String = "USER"
)
