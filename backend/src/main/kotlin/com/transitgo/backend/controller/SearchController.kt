package com.transitgo.backend.controller

import com.transitgo.backend.dto.RouteDto
import com.transitgo.backend.service.RouteService
import org.springframework.web.bind.annotation.*

@RestController
@CrossOrigin(origins = ["*"])
@RequestMapping("/api/search")
class SearchController(private val routeService: RouteService) {

    @GetMapping
    fun search(
        @RequestParam(required = false) from: String?,
        @RequestParam(required = false) to: String?
    ): List<RouteDto> {
        return routeService.searchRoutes(from, to)
    }
}
