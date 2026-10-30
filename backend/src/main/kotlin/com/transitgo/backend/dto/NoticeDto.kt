package com.transitgo.backend.dto

data class NoticeDto(
    val id: String,
    val title: String,
    val description: String,
    val category: String, // "ADVISORY", "HELPLINE", "SCHEDULE", "EMERGENCY"
    val publishedAt: String,
    val source: String,
    val isVerified: Boolean = true,
    val actionUrl: String? = null
)
