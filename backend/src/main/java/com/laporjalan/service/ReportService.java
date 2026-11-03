package com.laporjalan.service;

import com.laporjalan.dto.request.CreateReportRequest;
import com.laporjalan.dto.request.ResubmitReportRequest;
import com.laporjalan.dto.request.UpdateReportRequest;
import com.laporjalan.dto.request.UpdateReportStatusRequest;
import com.laporjalan.dto.response.ReportResponse;
import com.laporjalan.model.entity.Report;
import com.laporjalan.model.entity.ReportStatusLog;
import com.laporjalan.model.entity.User;
import com.laporjalan.model.enums.ReportSeverity;
import com.laporjalan.model.enums.ReportStatus;
import com.laporjalan.repository.ReportRepository;
import com.laporjalan.repository.ReportStatusLogRepository;
import com.laporjalan.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class ReportService {

    private static final double MAX_RADIUS_KM = 10.0;

    private final ReportRepository reportRepository;
    private final UserRepository userRepository;
    private final ReportStatusLogRepository reportStatusLogRepository;
    private final ReportPhotoStorageService photoStorageService;

    public ReportService(
            ReportRepository reportRepository,
            UserRepository userRepository,
            ReportStatusLogRepository reportStatusLogRepository,
            ReportPhotoStorageService photoStorageService) {
        this.reportRepository = reportRepository;
        this.userRepository = userRepository;
        this.reportStatusLogRepository = reportStatusLogRepository;
        this.photoStorageService = photoStorageService;
    }

    public ReportResponse createReport(String reporterEmail, CreateReportRequest request) {
        User reporter = getUserByEmail(reporterEmail);

        Report report = new Report();
        report.setReporter(reporter);
        report.setDescription(request.getDescription());
        report.setSeverity(request.getSeverity());
        report.setLatitude(request.getLatitude());
        report.setLongitude(request.getLongitude());
        report.setLocationName(request.getLocationName());
        report.setPhotoUrls(request.getPhotoUrls().toArray(new String[0]));
        report.setStatus(ReportStatus.DILAPORKAN);

        Report savedReport = reportRepository.save(report);
        saveStatusLog(savedReport, null, ReportStatus.DILAPORKAN, reporter, null);
        return mapToPrivateResponse(savedReport);
    }

    public ReportResponse getReportDetail(Long reportId, String requesterEmail) {
        Report report = getReport(reportId);
        boolean isMine = requesterEmail != null
                && report.getReporter().getEmail().equals(requesterEmail);
        return mapReport(report, false, isMine, true);
    }

    public ReportResponse updateReport(Long reportId, String reporterEmail, UpdateReportRequest request) {
        Report report = getReport(reportId);
        assertOwner(report, reporterEmail);

        if (report.getStatus() != ReportStatus.DILAPORKAN) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Only reported reports can be updated");
        }

        if (request.getDescription() != null) {
            report.setDescription(request.getDescription());
        }
        if (request.getSeverity() != null) {
            report.setSeverity(request.getSeverity());
        }
        if (request.getLatitude() != null) {
            report.setLatitude(request.getLatitude());
        }
        if (request.getLongitude() != null) {
            report.setLongitude(request.getLongitude());
        }
        if (request.getLocationName() != null) {
            report.setLocationName(request.getLocationName());
        }
        if (request.getPhotoUrls() != null) {
            report.setPhotoUrls(request.getPhotoUrls().toArray(new String[0]));
        }

        return mapToPrivateResponse(reportRepository.save(report));
    }

    public ReportResponse resubmitReport(
            Long reportId,
            String reporterEmail,
            ResubmitReportRequest request) {
        Report report = getReport(reportId);
        User reporter = getUserByEmail(reporterEmail);
        assertOwner(report, reporterEmail);

        if (report.getStatus() != ReportStatus.DITOLAK) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Only rejected reports can be resubmitted");
        }

        if (request.getDescription() != null && !request.getDescription().trim().isEmpty()) {
            report.setDescription(request.getDescription().trim());
        }
        if (request.getPhotoUrls() != null && !request.getPhotoUrls().isEmpty()) {
            report.setPhotoUrls(request.getPhotoUrls().toArray(new String[0]));
        }

        report.setStatus(ReportStatus.DILAPORKAN);
        report.setRejectReason(null);
        report.setRejectNote(null);

        Report savedReport = reportRepository.save(report);
        saveStatusLog(
                savedReport,
                ReportStatus.DITOLAK,
                ReportStatus.DILAPORKAN,
                reporter,
                "Laporan diajukan ulang oleh pelapor.");
        return mapToPrivateResponse(savedReport);
    }

    public void deleteReport(Long reportId, String reporterEmail) {
        Report report = getReport(reportId);
        assertOwner(report, reporterEmail);

        if (report.getStatus() != ReportStatus.DILAPORKAN) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT, "Only reported reports can be deleted");
        }

        photoStorageService.deletePhotos(List.of(report.getPhotoUrls()));
        reportStatusLogRepository.deleteAllInBatch(
                reportStatusLogRepository.findByReportIdOrderByCreatedAtDesc(reportId));
        reportRepository.delete(report);
    }

    public ReportResponse updateReportStatus(
            Long reportId,
            String officerEmail,
            UpdateReportStatusRequest request) {
        Report report = getReport(reportId);
        User officer = getUserByEmail(officerEmail);
        ReportStatus oldStatus = report.getStatus();
        ReportStatus newStatus = request.getNewStatus();

        if (!isAllowedOfficerTransition(oldStatus, newStatus)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Invalid report status transition from " + oldStatus + " to " + newStatus);
        }

        if (newStatus == ReportStatus.DITOLAK && request.getRejectReason() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Reject reason is required");
        }

        report.setStatus(newStatus);
        if (newStatus == ReportStatus.DITOLAK) {
            report.setRejectReason(request.getRejectReason());
            report.setRejectNote(request.getNote());
        }

        Report savedReport = reportRepository.save(report);
        saveStatusLog(savedReport, oldStatus, newStatus, officer, request.getNote());
        return mapToPrivateResponse(savedReport);
    }

    public List<ReportResponse> getReportsByReporter(String reporterEmail) {
        User reporter = getUserByEmail(reporterEmail);
        return reportRepository.findByReporterId(reporter.getId()).stream()
                .map(this::mapToPrivateResponse)
                .toList();
    }

    public List<ReportResponse> getAllReports() {
        return reportRepository.findAll().stream()
                .map(this::mapToPrivateResponse)
                .toList();
    }

    public List<ReportResponse> getReportsByFilter(
            ReportStatus status,
            ReportSeverity severity) {
        List<Report> reports;
        if (status != null && severity != null) {
            reports = reportRepository.findByStatusAndSeverity(status, severity);
        } else if (status != null) {
            reports = reportRepository.findByStatus(status);
        } else if (severity != null) {
            reports = reportRepository.findBySeverity(severity);
        } else {
            reports = reportRepository.findAll();
        }
        return reports.stream().map(this::mapToPrivateResponse).toList();
    }

    public List<ReportResponse> getNearbyReports(
            Double latitude,
            Double longitude,
            Double radiusKm) {
        validateCoordinates(latitude, longitude);
        double effectiveRadiusKm = Math.min(Math.max(radiusKm, 0), MAX_RADIUS_KM);
        return reportRepository.findAll().stream()
                .filter(report -> distanceInKm(latitude, longitude,
                        report.getLatitude(), report.getLongitude()) <= effectiveRadiusKm)
                .map(this::mapToPublicResponse)
                .toList();
    }

    private Report getReport(Long reportId) {
        return reportRepository.findById(reportId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Report not found"));
    }

    private User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
    }

    private void assertOwner(Report report, String reporterEmail) {
        if (!report.getReporter().getEmail().equals(reporterEmail)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You do not own this report");
        }
    }

    private boolean isAllowedOfficerTransition(ReportStatus from, ReportStatus to) {
        return (from == ReportStatus.DILAPORKAN
                && (to == ReportStatus.DIVERIFIKASI || to == ReportStatus.DITOLAK))
                || (from == ReportStatus.DIVERIFIKASI && to == ReportStatus.DIPERBAIKI);
    }

    private void saveStatusLog(
            Report report,
            ReportStatus fromStatus,
            ReportStatus toStatus,
            User changedBy,
            String note) {
        ReportStatusLog log = new ReportStatusLog();
        log.setReport(report);
        log.setFromStatus(fromStatus);
        log.setToStatus(toStatus);
        log.setChangedByRole(changedBy.getRole());
        log.setChangedByUser(changedBy);
        log.setNote(note);
        reportStatusLogRepository.save(log);
    }

    private ReportResponse mapToPublicResponse(Report report) {
        return mapReport(report, false, false, false);
    }

    private ReportResponse mapToPrivateResponse(Report report) {
        return mapReport(report, true, false, false);
    }

    private ReportResponse mapReport(
            Report report,
            boolean includeReporter,
            boolean isMine,
            boolean includeStatusHistory) {
        ReportResponse response = new ReportResponse();
        response.setId(report.getId());
        response.setDescription(report.getDescription());
        response.setSeverity(report.getSeverity());
        response.setStatus(report.getStatus());
        response.setLatitude(report.getLatitude());
        response.setLongitude(report.getLongitude());
        response.setLocationName(report.getLocationName());
        response.setPhotoUrls(List.of(report.getPhotoUrls()));
        response.setRejectReason(report.getRejectReason());
        response.setRejectNote(report.getRejectNote());
        response.setMine(isMine);
        response.setCreatedAt(report.getCreatedAt());
        response.setUpdatedAt(report.getUpdatedAt());

        if (includeReporter) {
            ReportResponse.ReporterInfo reporterInfo = new ReportResponse.ReporterInfo();
            reporterInfo.setId(report.getReporter().getId());
            reporterInfo.setName(report.getReporter().getName());
            reporterInfo.setEmail(report.getReporter().getEmail());
            response.setReporter(reporterInfo);
        }
        if (includeStatusHistory) {
            response.setStatusHistory(reportStatusLogRepository
                    .findByReportIdOrderByCreatedAtAsc(report.getId())
                    .stream()
                    .map(this::mapStatusHistory)
                    .toList());
        }
        return response;
    }

    private ReportResponse.StatusHistoryItem mapStatusHistory(ReportStatusLog log) {
        ReportResponse.StatusHistoryItem item = new ReportResponse.StatusHistoryItem();
        item.setId(log.getId());
        item.setFromStatus(log.getFromStatus());
        item.setToStatus(log.getToStatus());
        item.setChangedByRole(log.getChangedByRole());
        item.setNote(log.getNote());
        item.setCreatedAt(log.getCreatedAt());
        return item;
    }

    private void validateCoordinates(double latitude, double longitude) {
        if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid coordinates");
        }
    }

    private double distanceInKm(
            double latitudeA,
            double longitudeA,
            double latitudeB,
            double longitudeB) {
        double earthRadiusKm = 6371.0;
        double latitudeDifference = Math.toRadians(latitudeB - latitudeA);
        double longitudeDifference = Math.toRadians(longitudeB - longitudeA);
        double a = Math.sin(latitudeDifference / 2) * Math.sin(latitudeDifference / 2)
                + Math.cos(Math.toRadians(latitudeA))
                * Math.cos(Math.toRadians(latitudeB))
                * Math.sin(longitudeDifference / 2)
                * Math.sin(longitudeDifference / 2);
        return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
