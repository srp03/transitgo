package com.transitgo.backend.controller

import com.transitgo.backend.dto.RouteSummaryDto
import com.transitgo.backend.dto.StopDto
import com.transitgo.backend.dto.StopWithRoutesDto
import com.transitgo.backend.service.StopService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@CrossOrigin(origins = ["*"])
@RequestMapping("/api/stops")
class StopController(private val stopService: StopService) {

    @GetMapping
    fun getAllStops(): List<StopDto> {
        return stopService.getAllStops()
    }

    @GetMapping("/{id}")
    fun getStopById(@PathVariable id: Long): ResponseEntity<StopWithRoutesDto> {
        val stop = stopService.getStopById(id)
        return if (stop != null) ResponseEntity.ok(stop) else ResponseEntity.notFound().build()
    }

    @GetMapping("/{id}/routes")
    fun getRoutesForStop(@PathVariable id: Long): List<RouteSummaryDto> {
        return stopService.getRoutesForStop(id)
    }

    @GetMapping("/nearby")
    fun getNearbyStops(
        @RequestParam(required = false) latitude: Double?,
        @RequestParam(required = false) longitude: Double?,
        @RequestParam(required = false) lat: Double?,
        @RequestParam(required = false) lng: Double?,
        @RequestParam(defaultValue = "5.0") radius: Double
    ): List<StopDto> {
        val effectiveLat = latitude ?: lat ?: 19.1860 // Default Thane Station
        val effectiveLng = longitude ?: lng ?: 72.9759
        return stopService.getNearbyStops(effectiveLat, effectiveLng, radius)
    }

    @GetMapping("/search")
    fun searchStops(@RequestParam query: String): List<StopDto> {
        return stopService.searchStopsByName(query)
    }
}
