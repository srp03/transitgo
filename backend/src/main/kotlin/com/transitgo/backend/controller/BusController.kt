package com.transitgo.backend.controller

import com.transitgo.backend.dto.BusLocationDto
import com.transitgo.backend.entity.Bus
import com.transitgo.backend.service.BusService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@CrossOrigin(origins = ["*"])
@RequestMapping("/api/buses")
class BusController(private val busService: BusService) {

    @GetMapping
    fun getAllBuses(): List<Bus> {
        return busService.getAllBuses()
    }

    @GetMapping("/{id}")
    fun getBusById(@PathVariable id: Long): ResponseEntity<Bus> {
        val bus = busService.getBusById(id)
        return if (bus != null) ResponseEntity.ok(bus) else ResponseEntity.notFound().build()
    }

    @GetMapping("/live")
    fun getLiveBusLocations(): List<BusLocationDto> {
        return busService.getLiveBusLocations()
    }

    @GetMapping("/{id}/location")
    fun getBusLocation(@PathVariable id: Long): ResponseEntity<BusLocationDto> {
        val location = busService.getBusLocation(id)
        return if (location != null) ResponseEntity.ok(location) else ResponseEntity.notFound().build()
    }
}
