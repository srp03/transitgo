package com.transitgo.backend.service

import com.transitgo.backend.dto.BookingDto
import com.transitgo.backend.dto.CreateBookingRequest
import com.transitgo.backend.entity.Booking
import com.transitgo.backend.repository.BookingRepository
import com.transitgo.backend.repository.RouteRepository
import com.transitgo.backend.repository.RouteStopRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Service
class BookingService(
    private val bookingRepository: BookingRepository,
    private val routeRepository: RouteRepository,
    private val routeStopRepository: RouteStopRepository
) {

    @Transactional
    fun createBooking(request: CreateBookingRequest): BookingDto {
        val route = routeRepository.findById(request.routeId).orElseThrow {
            IllegalArgumentException("Route with id ${request.routeId} not found")
        }

        if (request.sourceStop.isBlank()) {
            throw IllegalArgumentException("Source stop cannot be empty")
        }
        if (request.destinationStop.isBlank()) {
            throw IllegalArgumentException("Destination stop cannot be empty")
        }
        if (request.sourceStop.equals(request.destinationStop, ignoreCase = true)) {
            throw IllegalArgumentException("Source and destination stops cannot be the same")
        }

        val passengers = request.passengerCount.coerceIn(1, 6)

        // Calculate verified fare
        val routeStops = routeStopRepository.findByRouteIdOrderByStopSequenceAsc(route.id!!)
        val srcIdx = routeStops.indexOfFirst { it.stop?.name?.equals(request.sourceStop, ignoreCase = true) == true }
        val dstIdx = routeStops.indexOfFirst { it.stop?.name?.equals(request.destinationStop, ignoreCase = true) == true }

        val calculatedFare = if (srcIdx != -1 && dstIdx != -1 && dstIdx > srcIdx) {
            val stopSpan = dstIdx - srcIdx
            maxOf(10.0, stopSpan * 5.0) * passengers
        } else {
            // Default flat minimum fare for demo
            maxOf(10.0, (request.fare ?: 15.0)) * passengers
        }

        val refCode = generateBookingReference()
        val bookedAt = System.currentTimeMillis()
        val qrPayload = "TRANSITGO|TMT|REF:$refCode|R:${route.routeNumber}|FROM:${request.sourceStop}|TO:${request.destinationStop}|PAX:$passengers|FARE:INR $calculatedFare|DEMO"

        val booking = Booking(
            bookingReference = refCode,
            routeId = route.id!!,
            routeNumber = route.routeNumber,
            routeName = "${route.source} → ${route.destination}",
            sourceStop = request.sourceStop,
            destinationStop = request.destinationStop,
            departureTime = request.departureTime.ifBlank { "Immediate / Next Bus" },
            passengerCount = passengers,
            fare = calculatedFare,
            status = "CONFIRMED",
            paymentMethod = "UPI_DEMO",
            paymentStatus = "PAID_DEMO",
            upiId = request.upiId ?: "passenger@upi",
            bookedAt = bookedAt,
            qrPayload = qrPayload
        )

        val saved = bookingRepository.save(booking)
        return toDto(saved)
    }

    fun getAllBookings(): List<BookingDto> {
        return bookingRepository.findAllByOrderByBookedAtDesc().map { toDto(it) }
    }

    fun getBookingById(id: Long): BookingDto? {
        val booking = bookingRepository.findById(id).orElse(null) ?: return null
        return toDto(booking)
    }

    fun getBookingByReference(reference: String): BookingDto? {
        val booking = bookingRepository.findByBookingReference(reference) ?: return null
        return toDto(booking)
    }

    @Transactional
    fun cancelBooking(id: Long): BookingDto? {
        val booking = bookingRepository.findById(id).orElse(null) ?: return null
        if (booking.status == "CANCELLED") {
            return toDto(booking)
        }
        booking.status = "CANCELLED"
        val updated = bookingRepository.save(booking)
        return toDto(updated)
    }

    private fun generateBookingReference(): String {
        val timestamp = System.currentTimeMillis().toString(36).uppercase()
        val randomSuffix = UUID.randomUUID().toString().replace("-", "").take(4).uppercase()
        return "TG$timestamp$randomSuffix"
    }

    private fun toDto(b: Booking): BookingDto {
        return BookingDto(
            id = b.id!!,
            bookingReference = b.bookingReference,
            routeId = b.routeId,
            routeNumber = b.routeNumber,
            routeName = b.routeName,
            sourceStop = b.sourceStop,
            destinationStop = b.destinationStop,
            departureTime = b.departureTime,
            passengerCount = b.passengerCount,
            fare = b.fare,
            status = b.status,
            paymentMethod = b.paymentMethod,
            paymentStatus = b.paymentStatus,
            upiId = b.upiId,
            bookedAt = b.bookedAt,
            qrPayload = b.qrPayload,
            isDemo = true,
            notice = "Demo ticket — Not an official TMT paper ticket"
        )
    }
}
