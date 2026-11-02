package com.laporjalan.controller;

import com.laporjalan.dto.request.CreateReportRequest;
import com.laporjalan.dto.request.ResubmitReportRequest;
import com.laporjalan.dto.request.UpdateReportRequest;
import com.laporjalan.dto.request.UpdateReportStatusRequest;
import com.laporjalan.dto.response.ReportResponse;
import com.laporjalan.model.enums.ReportSeverity;
import com.laporjalan.model.enums.ReportStatus;
import com.laporjalan.service.ReportService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @PostMapping
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ReportResponse> createReport(
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody CreateReportRequest request) {
        return ResponseEntity.ok(reportService.createReport(userDetails.getUsername(), request));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ReportResponse> getReportById(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(reportService.getReportDetail(
                id,
                userDetails == null ? null : userDetails.getUsername()));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ReportResponse> updateReport(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody UpdateReportRequest request) {
        return ResponseEntity.ok(reportService.updateReport(id, userDetails.getUsername(), request));
    }

    @PostMapping("/{id}/resubmit")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ReportResponse> resubmitReport(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody ResubmitReportRequest request) {
        return ResponseEntity.ok(reportService.resubmitReport(
                id,
                userDetails.getUsername(),
                request));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<Void> deleteReport(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails) {
        reportService.deleteReport(id, userDetails.getUsername());
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasRole('OFFICER')")
    public ResponseEntity<ReportResponse> updateReportStatus(
            @PathVariable Long id,
            @AuthenticationPrincipal UserDetails userDetails,
            @Valid @RequestBody UpdateReportStatusRequest request) {
        return ResponseEntity.ok(reportService.updateReportStatus(id, userDetails.getUsername(), request));
    }

    @GetMapping("/my-reports")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<List<ReportResponse>> getReportsByReporter(
            @AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(reportService.getReportsByReporter(userDetails.getUsername()));
    }

    @GetMapping("/all")
    @PreAuthorize("hasRole('OFFICER')")
    public ResponseEntity<List<ReportResponse>> getAllReports() {
        return ResponseEntity.ok(reportService.getAllReports());
    }

    @GetMapping("/filter")
    @PreAuthorize("hasRole('OFFICER')")
    public ResponseEntity<List<ReportResponse>> getReportsByFilter(
            @RequestParam(required = false) ReportStatus status,
            @RequestParam(required = false) ReportSeverity severity) {
        return ResponseEntity.ok(reportService.getReportsByFilter(status, severity));
    }

    @GetMapping("/nearby")
    public ResponseEntity<List<ReportResponse>> getNearbyReports(
            @RequestParam Double latitude,
            @RequestParam Double longitude,
            @RequestParam(defaultValue = "10.0") Double radiusKm) {
        return ResponseEntity.ok(reportService.getNearbyReports(latitude, longitude, radiusKm));
    }
}
