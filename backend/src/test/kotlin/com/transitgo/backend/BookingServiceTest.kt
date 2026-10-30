package com.transitgo.backend

import com.transitgo.backend.dto.CreateBookingRequest
import com.transitgo.backend.entity.Route
import com.transitgo.backend.repository.BookingRepository
import com.transitgo.backend.repository.RouteRepository
import com.transitgo.backend.repository.RouteStopRepository
import com.transitgo.backend.service.BookingService
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.transaction.annotation.Transactional

@SpringBootTest
class BookingServiceTest {

    @Autowired
    private lateinit var bookingService: BookingService

    @Autowired
    private lateinit var routeRepository: RouteRepository

    @Autowired
    private lateinit var bookingRepository: BookingRepository

    @Test
    @Transactional
    fun testCreateAndCancelBooking() {
        val routes = routeRepository.findByAgencyId("TMT")
        assertFalse(routes.isEmpty(), "TMT routes should exist in database")
        val sampleRoute = routes.first()

        val req = CreateBookingRequest(
            routeId = sampleRoute.id!!,
            sourceStop = sampleRoute.source,
            destinationStop = sampleRoute.destination,
            departureTime = "10:30 AM",
            passengerCount = 2,
            fare = 25.0,
            upiId = "passenger@okhdfcbank"
        )

        val created = bookingService.createBooking(req)
        assertNotNull(created.id)
        assertTrue(created.bookingReference.startsWith("TG"))
        assertEquals("CONFIRMED", created.status)
        assertEquals(2, created.passengerCount)
        assertTrue(created.fare >= 10.0)
        assertTrue(created.qrPayload.contains(created.bookingReference))

        // Query by reference
        val found = bookingService.getBookingByReference(created.bookingReference)
        assertNotNull(found)
        assertEquals(created.id, found?.id)

        // Cancel booking
        val cancelled = bookingService.cancelBooking(created.id)
        assertNotNull(cancelled)
        assertEquals("CANCELLED", cancelled?.status)
    }

    @Test
    fun testInvalidBookingRejectsIdenticalStops() {
        val routes = routeRepository.findByAgencyId("TMT")
        if (routes.isNotEmpty()) {
            val sampleRoute = routes.first()
            val req = CreateBookingRequest(
                routeId = sampleRoute.id!!,
                sourceStop = "Thane Station",
                destinationStop = "Thane Station",
                departureTime = "11:00 AM",
                passengerCount = 1
            )
            assertThrows(IllegalArgumentException::class.java) {
                bookingService.createBooking(req)
            }
        }
    }
}
