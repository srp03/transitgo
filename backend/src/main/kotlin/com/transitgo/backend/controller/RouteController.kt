package com.transitgo.backend.controller

import com.transitgo.backend.dto.BusLocationDto
import com.transitgo.backend.dto.RouteDto
import com.transitgo.backend.dto.ScheduleDto
import com.transitgo.backend.dto.StopDto
import com.transitgo.backend.service.RouteService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@CrossOrigin(origins = ["*"])
@RequestMapping("/api/routes")
class RouteController(
    private val routeService: RouteService
) {

    @GetMapping
    fun getAllRoutes(): List<RouteDto> {
        return routeService.getAllRoutes()
    }

    @GetMapping("/{id}")
    fun getRouteById(@PathVariable id: Long): ResponseEntity<RouteDto> {
        val route = routeService.getRouteById(id)
        return if (route != null) ResponseEntity.ok(route) else ResponseEntity.notFound().build()
    }

    @GetMapping("/{id}/stops")
    fun getRouteStops(@PathVariable id: Long): List<StopDto> {
        return routeService.getRouteStops(id)
    }

    @GetMapping("/{id}/schedule")
    fun getRouteSchedule(@PathVariable id: Long): List<ScheduleDto> {
        return routeService.getRouteSchedules(id)
    }

    @GetMapping("/{id}/buses")
    fun getRouteBuses(@PathVariable id: Long): List<BusLocationDto> {
        return routeService.getRouteBuses(id)
    }

    @GetMapping("/search")
    fun searchRoutes(
        @RequestParam(required = false) from: String?,
        @RequestParam(required = false) to: String?,
        @RequestParam(required = false) transportType: String?
    ): List<RouteDto> {
        return routeService.searchRoutes(from, to)
    }
}
