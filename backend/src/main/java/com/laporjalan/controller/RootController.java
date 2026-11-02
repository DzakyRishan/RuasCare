package com.laporjalan.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/** Status API saat base URL dibuka langsung di browser. */
@RestController
public class RootController {

    @GetMapping("/")
    public ResponseEntity<Map<String, String>> status() {
        return ResponseEntity.ok(Map.of(
                "name", "Lapor Jalan API",
                "status", "running",
                "info", "Ini REST API untuk aplikasi Flutter. Endpoint ada di /api/..."));
    }
}
