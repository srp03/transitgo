package com.transitgo.backend.controller

import com.transitgo.backend.dto.NoticeDto
import org.springframework.web.bind.annotation.CrossOrigin
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@CrossOrigin(origins = ["*"])
@RequestMapping("/api/notices")
class NoticeController {

    @GetMapping
    fun getVerifiedNotices(): List<NoticeDto> {
        return listOf(
            NoticeDto(
                id = "TMT-NOTICE-01",
                title = "TMT Control Room Helpline",
                description = "For bus inquiry, lost & found, and passenger assistance, contact TMT Thane Station Control Room at +91 022 2539 4922 (Hours: 06:00 to 22:00).",
                category = "HELPLINE",
                publishedAt = "2026-10-01",
                source = "Thane Municipal Transport Corporation",
                isVerified = true,
                actionUrl = "tel:+9102225394922"
            ),
            NoticeDto(
                id = "TMT-NOTICE-02",
                title = "AC Electric Bus Fleet Deployment",
                description = "Zero-emission Electric AC buses deployed across primary arterial routes connecting Thane Station to Ghodbunder Road, Anand Nagar, and Borivali.",
                category = "ADVISORY",
                publishedAt = "2026-09-15",
                source = "TMC Smart City Mission",
                isVerified = true,
                actionUrl = "https://www.thanecity.gov.in"
            ),
            NoticeDto(
                id = "TMT-NOTICE-03",
                title = "GTFS Timetable Operations Notice",
                description = "Bus schedules displayed in TransitGo reflect GTFS public timetable data. Actual departure times may vary based on local traffic conditions.",
                category = "SCHEDULE",
                publishedAt = "2026-08-19",
                source = "TransitGo Operations",
                isVerified = true
            )
        )
    }
}
