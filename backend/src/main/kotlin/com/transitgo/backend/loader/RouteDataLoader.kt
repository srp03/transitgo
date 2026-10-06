package com.transitgo.backend.loader

import com.transitgo.backend.service.GtfsImporterService
import org.slf4j.LoggerFactory
import org.springframework.boot.CommandLineRunner
import org.springframework.stereotype.Component
import java.io.File

@Component
class RouteDataLoader(
    private val gtfsImporterService: GtfsImporterService
) : CommandLineRunner {

    private val logger = LoggerFactory.getLogger(RouteDataLoader::class.java)

    override fun run(vararg args: String) {
        val possiblePaths = listOf(
            File("d:/public/database"),
            File("database"),
            File("../database"),
            File("backend/database")
        )

        val targetDir = possiblePaths.firstOrNull { it.exists() && it.isDirectory }

        if (targetDir != null) {
            logger.info("Found GTFS dataset directory at: ${targetDir.absolutePath}")
            gtfsImporterService.importTmtData(targetDir)
        } else {
            logger.error("Could not locate GTFS database directory in known paths!")
        }
    }
}