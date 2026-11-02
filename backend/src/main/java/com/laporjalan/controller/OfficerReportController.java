package com.laporjalan.controller;

import com.laporjalan.dto.response.ReportResponse;
import com.laporjalan.model.enums.ReportSeverity;
import com.laporjalan.model.enums.ReportStatus;
import com.laporjalan.service.ReportService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Endpoints khusus dashboard petugas. */
@RestController
@RequestMapping("/api/officer")
@PreAuthorize("hasRole('OFFICER')")
public class OfficerReportController {

    private final ReportService reportService;

    public OfficerReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping("/reports")
    public ResponseEntity<List<ReportResponse>> getReports(
            @RequestParam(required = false) ReportStatus status,
            @RequestParam(required = false) ReportSeverity severity) {
        return ResponseEntity.ok(reportService.getReportsByFilter(status, severity));
    }
}
