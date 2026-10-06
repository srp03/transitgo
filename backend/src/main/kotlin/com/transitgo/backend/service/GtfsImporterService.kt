package com.transitgo.backend.service

import com.transitgo.backend.entity.*
import com.transitgo.backend.repository.*
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.io.File

@Service
class GtfsImporterService(
    private val routeRepository: RouteRepository,
    private val stopRepository: StopRepository,
    private val tripRepository: TripRepository,
    private val stopTimeRepository: StopTimeRepository,
    private val routeStopRepository: RouteStopRepository,
    private val busRepository: BusRepository,
    private val busLocationRepository: BusLocationRepository
) {
    private val logger = LoggerFactory.getLogger(GtfsImporterService::class.java)

    @Transactional
    fun importTmtData(gtfsDir: File) {
        if (!gtfsDir.exists() || !gtfsDir.isDirectory) {
            logger.warn("GTFS directory does not exist at: ${gtfsDir.absolutePath}")
            return
        }

        // Idempotency check: if TMT routes already exist, skip import
        if (routeRepository.findByAgencyId("TMT").isNotEmpty()) {
            logger.info("TMT GTFS dataset already imported in database. Skipping duplicate import.")
            return
        }

        logger.info("Starting TMT GTFS dataset import from ${gtfsDir.absolutePath}...")

        val routesFile = File(gtfsDir, "routes.txt")
        val stopsFile = File(gtfsDir, "stops.txt")
        val tripsFile = File(gtfsDir, "trips.txt")
        val stopTimesFile = File(gtfsDir, "stop_times.txt")

        if (!routesFile.exists() || !stopsFile.exists() || !tripsFile.exists() || !stopTimesFile.exists()) {
            logger.error("Missing required GTFS text files in ${gtfsDir.absolutePath}")
            return
        }

        // 1. Import Stops first
        val stopMap = mutableMapOf<String, Stop>()
        stopsFile.useLines { lines ->
            val iterator = lines.iterator()
            if (!iterator.hasNext()) return@useLines
            val header = iterator.next().split(",").map { it.trim('"', ' ') }
            val stopIdIdx = header.indexOf("stop_id")
            val nameIdx = header.indexOf("stop_name")
            val latIdx = header.indexOf("stop_lat")
            val lonIdx = header.indexOf("stop_lon")

            val batch = mutableListOf<Stop>()
            iterator.forEachRemaining { line ->
                val cols = parseCsvLine(line)
                if (cols.size > stopIdIdx) {
                    val sId = cols[stopIdIdx]
                    if (sId.startsWith("TMT_", ignoreCase = true) || !sId.contains("_")) {
                        val name = if (nameIdx != -1 && cols.size > nameIdx) cols[nameIdx] else sId
                        val lat = if (latIdx != -1 && cols.size > latIdx) cols[latIdx].toDoubleOrNull() ?: 0.0 else 0.0
                        val lon = if (lonIdx != -1 && cols.size > lonIdx) cols[lonIdx].toDoubleOrNull() ?: 0.0 else 0.0

                        val stop = Stop(gtfsStopId = sId, name = name, latitude = lat, longitude = lon)
                        batch.add(stop)
                        if (batch.size >= 500) {
                            stopRepository.saveAll(batch).forEach { stopMap[it.gtfsStopId] = it }
                            batch.clear()
                        }
                    }
                }
            }
            if (batch.isNotEmpty()) {
                stopRepository.saveAll(batch).forEach { stopMap[it.gtfsStopId] = it }
                batch.clear()
            }
        }
        logger.info("Imported ${stopMap.size} Stops.")

        // 2. Import TMT Routes
        val tmtRouteMap = mutableMapOf<String, Route>()
        routesFile.useLines { lines ->
            val iterator = lines.iterator()
            if (!iterator.hasNext()) return@useLines
            val header = iterator.next().split(",").map { it.trim('"', ' ') }
            val routeIdIdx = header.indexOf("route_id")
            val agencyIdIdx = header.indexOf("agency_id")
            val shortNameIdx = header.indexOf("route_short_name")
            val longNameIdx = header.indexOf("route_long_name")
            val typeIdx = header.indexOf("route_type")

            iterator.forEachRemaining { line ->
                val cols = parseCsvLine(line)
                if (cols.size > routeIdIdx) {
                    val rId = cols[routeIdIdx]
                    val agency = if (agencyIdIdx != -1 && cols.size > agencyIdIdx) cols[agencyIdIdx] else ""

                    if (agency.equals("TMT", ignoreCase = true) || rId.startsWith("TMT_", ignoreCase = true)) {
                        val shortName = if (shortNameIdx != -1 && cols.size > shortNameIdx) cols[shortNameIdx] else rId
                        val longName = if (longNameIdx != -1 && cols.size > longNameIdx) cols[longNameIdx] else shortName
                        val rType = if (typeIdx != -1 && cols.size > typeIdx) cols[typeIdx].toIntOrNull() ?: 3 else 3
                        val (src, dest, dir) = parseSourceDestDirection(longName)

                        val route = Route(
                            gtfsRouteId = rId,
                            agencyId = "TMT",
                            routeNumber = shortName,
                            routeName = longName,
                            source = src,
                            destination = dest,
                            direction = dir,
                            routeType = rType,
                            active = true
                        )
                        tmtRouteMap[rId] = routeRepository.save(route)
                    }
                }
            }
        }
        logger.info("Imported ${tmtRouteMap.size} TMT Routes.")

        // 3. Import Trips for TMT Routes
        val tmtTripMap = mutableMapOf<String, Trip>()
        val routeToFirstTripMap = mutableMapOf<String, Trip>()

        tripsFile.useLines { lines ->
            val iterator = lines.iterator()
            if (!iterator.hasNext()) return@useLines
            val header = iterator.next().split(",").map { it.trim('"', ' ') }
            val routeIdIdx = header.indexOf("route_id")
            val tripIdIdx = header.indexOf("trip_id")
            val serviceIdIdx = header.indexOf("service_id")
            val headsignIdx = header.indexOf("trip_headsign")
            val dirIdx = header.indexOf("direction_id")

            val batch = mutableListOf<Trip>()
            iterator.forEachRemaining { line ->
                val cols = parseCsvLine(line)
                if (cols.size > routeIdIdx && cols.size > tripIdIdx) {
                    val rId = cols[routeIdIdx]
                    val tId = cols[tripIdIdx]

                    if (tmtRouteMap.containsKey(rId)) {
                        val route = tmtRouteMap[rId]!!
                        val sId = if (serviceIdIdx != -1 && cols.size > serviceIdIdx) cols[serviceIdIdx] else ""
                        val hSign = if (headsignIdx != -1 && cols.size > headsignIdx) cols[headsignIdx] else null
                        val dId = if (dirIdx != -1 && cols.size > dirIdx) cols[dirIdx].toIntOrNull() else null

                        val trip = Trip(gtfsTripId = tId, route = route, serviceId = sId, tripHeadsign = hSign, directionId = dId)
                        batch.add(trip)

                        if (batch.size >= 1000) {
                            tripRepository.saveAll(batch).forEach {
                                tmtTripMap[it.gtfsTripId] = it
                                val routeGtfsId = it.route?.gtfsRouteId
                                if (routeGtfsId != null && !routeToFirstTripMap.containsKey(routeGtfsId)) {
                                    routeToFirstTripMap[routeGtfsId] = it
                                }
                            }
                            batch.clear()
                        }
                    }
                }
            }
            if (batch.isNotEmpty()) {
                tripRepository.saveAll(batch).forEach {
                    tmtTripMap[it.gtfsTripId] = it
                    val routeGtfsId = it.route?.gtfsRouteId
                    if (routeGtfsId != null && !routeToFirstTripMap.containsKey(routeGtfsId)) {
                        routeToFirstTripMap[routeGtfsId] = it
                    }
                }
                batch.clear()
            }
        }
        logger.info("Imported ${tmtTripMap.size} TMT Trips.")

        // 4. Stream StopTimes and build RouteStop sequences for active TMT routes
        val repTripIds = routeToFirstTripMap.values.map { it.gtfsTripId }.toSet()
        val repTripToRouteMap = routeToFirstTripMap.entries.associate { (rId, trip) -> trip.gtfsTripId to tmtRouteMap[rId]!! }

        val routeStopsBuffer = mutableMapOf<Long, MutableList<RouteStop>>()

        stopTimesFile.useLines { lines ->
            val iterator = lines.iterator()
            if (!iterator.hasNext()) return@useLines
            val header = iterator.next().split(",").map { it.trim('"', ' ') }
            val tripIdIdx = header.indexOf("trip_id")
            val arrIdx = header.indexOf("arrival_time")
            val depIdx = header.indexOf("departure_time")
            val stopIdIdx = header.indexOf("stop_id")
            val seqIdx = header.indexOf("stop_sequence")

            iterator.forEachRemaining { line ->
                val cols = parseCsvLine(line)
                if (cols.size > tripIdIdx && cols.size > stopIdIdx) {
                    val tId = cols[tripIdIdx]
                    if (repTripIds.contains(tId)) {
                        val route = repTripToRouteMap[tId] ?: return@forEachRemaining
                        val sId = cols[stopIdIdx]
                        val stop = stopMap[sId] ?: return@forEachRemaining

                        val arr = if (arrIdx != -1 && cols.size > arrIdx) cols[arrIdx] else ""
                        val dep = if (depIdx != -1 && cols.size > depIdx) cols[depIdx] else ""
                        val seq = if (seqIdx != -1 && cols.size > seqIdx) cols[seqIdx].toIntOrNull() ?: 0 else 0

                        val rs = RouteStop(
                            route = route,
                            stop = stop,
                            stopSequence = seq,
                            direction = route.direction,
                            arrivalTime = arr,
                            departureTime = dep
                        )
                        routeStopsBuffer.computeIfAbsent(route.id!!) { mutableListOf() }.add(rs)
                    }
                }
            }
        }

        // Save RouteStop sequences
        val allRouteStops = mutableListOf<RouteStop>()
        routeStopsBuffer.forEach { (_, stopsList) ->
            val sorted = stopsList.sortedBy { it.stopSequence }
            allRouteStops.addAll(sorted)
        }
        routeStopRepository.saveAll(allRouteStops)
        logger.info("Saved ${allRouteStops.size} RouteStop entries for TMT routes.")

        // 5. Create Sample Active Buses assigned to TMT routes for optional simulation
        val sampleRoutes = tmtRouteMap.values.take(6)
        sampleRoutes.forEachIndexed { i, route ->
            val vehicleNo = "MH-04-TM-${1010 + i}"
            if (!busRepository.existsByVehicleNumber(vehicleNo)) {
                val bus = busRepository.save(
                    Bus(
                        vehicleNumber = vehicleNo,
                        route = route,
                        vehicleType = "TMT Electric AC Bus",
                        capacity = 40,
                        occupancyStatus = "Moderate",
                        status = "On time"
                    )
                )

                val routeStops = routeStopRepository.findByRouteIdOrderByStopSequenceAsc(route.id!!)
                val firstStop = routeStops.firstOrNull()?.stop
                val secondStop = routeStops.getOrNull(1)?.stop

                val lat = firstStop?.latitude ?: 19.1860
                val lng = firstStop?.longitude ?: 72.9759

                busLocationRepository.save(
                    BusLocation(
                        busId = bus.id!!,
                        routeId = route.id!!,
                        latitude = lat,
                        longitude = lng,
                        speed = 26.0,
                        heading = 45.0,
                        timestamp = System.currentTimeMillis(),
                        currentStopName = firstStop?.name ?: "Origin",
                        nextStopName = secondStop?.name ?: "Next",
                        etaMinutes = 5,
                        status = bus.status
                    )
                )
            }
        }

        logger.info("TMT GTFS dataset import completed successfully.")
    }

    private fun parseCsvLine(line: String): List<String> {
        val result = mutableListOf<String>()
        val cur = StringBuilder()
        var inQuotes = false

        for (ch in line) {
            when {
                ch == '"' -> inQuotes = !inQuotes
                ch == ',' && !inQuotes -> {
                    result.add(cur.toString().trim('"', ' '))
                    cur.setLength(0)
                }
                else -> cur.append(ch)
            }
        }
        result.add(cur.toString().trim('"', ' '))
        return result
    }

    private fun parseSourceDestDirection(longName: String): Triple<String, String, String> {
        var direction = ""
        var name = longName.trim()

        if (name.endsWith("(UP)", ignoreCase = true)) {
            direction = "UP"
            name = name.substring(0, name.length - 4).trim()
        } else if (name.endsWith("(DOWN)", ignoreCase = true)) {
            direction = "DOWN"
            name = name.substring(0, name.length - 6).trim()
        }

        val toParts = name.split(" to ", " To ", " TO ", " to", " To")
        return if (toParts.size >= 2) {
            Triple(toParts[0].trim(), toParts[1].trim(), direction)
        } else {
            Triple(name, name, direction)
        }
    }
}
