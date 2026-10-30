package com.transitgo.backend.repository

import com.transitgo.backend.entity.Booking
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface BookingRepository : JpaRepository<Booking, Long> {
    fun findByBookingReference(bookingReference: String): Booking?
    fun findAllByOrderByBookedAtDesc(): List<Booking>
    fun findByRouteIdOrderByBookedAtDesc(routeId: Long): List<Booking>
}
