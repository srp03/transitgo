package com.transitgo.backend.controller

import com.transitgo.backend.dto.BookingDto
import com.transitgo.backend.dto.CreateBookingRequest
import com.transitgo.backend.service.BookingService
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@CrossOrigin(origins = ["*"])
@RequestMapping("/api/bookings")
class BookingController(
    private val bookingService: BookingService
) {

    @PostMapping
    fun createBooking(@RequestBody request: CreateBookingRequest): ResponseEntity<Any> {
        return try {
            val booking = bookingService.createBooking(request)
            ResponseEntity.status(HttpStatus.CREATED).body(booking)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.badRequest().body(mapOf("error" to (e.message ?: "Invalid booking request")))
        } catch (e: Exception) {
            ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(mapOf("error" to "Failed to process booking"))
        }
    }

    @GetMapping
    fun getAllBookings(): List<BookingDto> {
        return bookingService.getAllBookings()
    }

    @GetMapping("/{id}")
    fun getBookingById(@PathVariable id: Long): ResponseEntity<BookingDto> {
        val booking = bookingService.getBookingById(id)
        return if (booking != null) ResponseEntity.ok(booking) else ResponseEntity.notFound().build()
    }

    @GetMapping("/ref/{ref}")
    fun getBookingByRef(@PathVariable ref: String): ResponseEntity<BookingDto> {
        val booking = bookingService.getBookingByReference(ref)
        return if (booking != null) ResponseEntity.ok(booking) else ResponseEntity.notFound().build()
    }

    @PostMapping("/{id}/cancel")
    fun cancelBooking(@PathVariable id: Long): ResponseEntity<Any> {
        val booking = bookingService.cancelBooking(id)
        return if (booking != null) {
            ResponseEntity.ok(booking)
        } else {
            ResponseEntity.notFound().build()
        }
    }
}
