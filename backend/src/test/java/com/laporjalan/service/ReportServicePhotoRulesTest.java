package com.laporjalan.service;

import com.laporjalan.dto.request.UpdateReportRequest;
import com.laporjalan.dto.request.UpdateReportStatusRequest;
import com.laporjalan.dto.response.ReportResponse;
import com.laporjalan.model.entity.Report;
import com.laporjalan.model.entity.ReportStatusLog;
import com.laporjalan.model.entity.User;
import com.laporjalan.model.enums.ReportSeverity;
import com.laporjalan.model.enums.ReportStatus;
import com.laporjalan.model.enums.UserRole;
import com.laporjalan.repository.ReportRepository;
import com.laporjalan.repository.ReportStatusLogRepository;
import com.laporjalan.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Menguji aturan foto di ReportService tanpa database dan tanpa jaringan:
 * bukti perbaikan wajib, status harus Diverifikasi, dan foto lama yang
 * dipertahankan harus milik laporan itu sendiri.
 */
class ReportServicePhotoRulesTest {

    private static final String OWNER_EMAIL = "warga@demo.id";
    private static final String OFFICER_EMAIL = "petugas@demo.id";
    private static final byte[] PNG = {
            (byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00
    };

    private ReportRepository reportRepository;
    private UserRepository userRepository;
    private ReportStatusLogRepository logRepository;
    private ReportPhotoStorageService storage;
    private ReportService service;
    private Report report;

    @BeforeEach
    void setUp() {
        reportRepository = mock(ReportRepository.class);
        userRepository = mock(UserRepository.class);
        logRepository = mock(ReportStatusLogRepository.class);
        storage = mock(ReportPhotoStorageService.class);
        service = new ReportService(reportRepository, userRepository, logRepository, storage);

        User owner = user(1L, OWNER_EMAIL, UserRole.CITIZEN);
        User officer = user(2L, OFFICER_EMAIL, UserRole.OFFICER);
        when(userRepository.findByEmail(OWNER_EMAIL)).thenReturn(Optional.of(owner));
        when(userRepository.findByEmail(OFFICER_EMAIL)).thenReturn(Optional.of(officer));

        report = new Report();
        report.setId(10L);
        report.setReporter(owner);
        report.setDescription("Lubang besar di lajur kiri jalan.");
        report.setSeverity(ReportSeverity.SEDANG);
        report.setStatus(ReportStatus.DILAPORKAN);
        report.setLatitude(-6.17);
        report.setLongitude(106.82);
        report.setPhotoUrls(new String[] {"/uploads/reports/a.jpg", "/uploads/reports/b.jpg"});
        when(reportRepository.findById(10L)).thenReturn(Optional.of(report));
        when(reportRepository.save(any(Report.class))).thenAnswer(call -> call.getArgument(0));
    }

    private User user(Long id, String email, UserRole role) {
        User user = new User();
        user.setId(id);
        user.setName(email);
        user.setEmail(email);
        user.setRole(role);
        return user;
    }

    private MultipartFile png(String name) {
        return new MockMultipartFile("photos", name, "image/png", PNG);
    }

    // ---------------------------------------------------------------- bukti perbaikan

    @Test
    void markFixedRejectsReportThatIsNotVerifiedYet() {
        ResponseStatusException error = assertThrows(
                ResponseStatusException.class,
                () -> service.markReportFixed(10L, OFFICER_EMAIL, "selesai", List.of(png("bukti.png"))));

        assertEquals(409, error.getStatusCode().value());
        verify(storage, never()).storeRepairPhotos(anyList());
    }

    @Test
    void markFixedStoresRepairPhotosAndLogsTheTransition() {
        report.setStatus(ReportStatus.DIVERIFIKASI);
        when(storage.storeRepairPhotos(anyList())).thenReturn(List.of("/uploads/reports/bukti.png"));

        ReportResponse response =
                service.markReportFixed(10L, OFFICER_EMAIL, "Jalan sudah ditambal", List.of(png("bukti.png")));

        assertEquals(ReportStatus.DIPERBAIKI, response.getStatus());
        assertEquals(List.of("/uploads/reports/bukti.png"), response.getRepairPhotoUrls());
        verify(logRepository).save(any(ReportStatusLog.class));
    }

    @Test
    void genericStatusEndpointCannotSetFixedWithoutPhotos() {
        report.setStatus(ReportStatus.DIVERIFIKASI);
        UpdateReportStatusRequest request = new UpdateReportStatusRequest();
        request.setNewStatus(ReportStatus.DIPERBAIKI);

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class,
                () -> service.updateReportStatus(10L, OFFICER_EMAIL, request));

        assertEquals(400, error.getStatusCode().value());
        assertEquals(ReportStatus.DIVERIFIKASI, report.getStatus());
    }

    // ---------------------------------------------------------------- edit laporan

    @Test
    void editRejectsKeepingAPhotoThatBelongsToAnotherReport() {
        UpdateReportRequest request = new UpdateReportRequest();
        request.setKeepPhotoUrls(List.of("/uploads/reports/a.jpg", "/uploads/reports/milik-orang-lain.jpg"));

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class,
                () -> service.updateReport(10L, OWNER_EMAIL, request, List.of()));

        assertEquals(400, error.getStatusCode().value());
        verify(reportRepository, never()).save(any(Report.class));
    }

    @Test
    void editRejectsFewerThanTwoPhotosInTotal() {
        UpdateReportRequest request = new UpdateReportRequest();
        request.setKeepPhotoUrls(List.of("/uploads/reports/a.jpg"));

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class,
                () -> service.updateReport(10L, OWNER_EMAIL, request, List.of()));

        assertEquals(400, error.getStatusCode().value());
    }

    @Test
    void editKeepsOnePhotoAddsOneAndDeletesTheRemovedFile() {
        UpdateReportRequest request = new UpdateReportRequest();
        request.setKeepPhotoUrls(List.of("/uploads/reports/a.jpg"));
        when(storage.storePhotos(anyList(), org.mockito.ArgumentMatchers.eq(0), org.mockito.ArgumentMatchers.eq(3)))
                .thenReturn(List.of("/uploads/reports/baru.png"));

        ReportResponse response = service.updateReport(10L, OWNER_EMAIL, request, List.of(png("baru.png")));

        assertEquals(
                List.of("/uploads/reports/a.jpg", "/uploads/reports/baru.png"),
                response.getPhotoUrls());
        verify(storage).deletePhotos(List.of("/uploads/reports/b.jpg"));
    }

    @Test
    void anotherCitizenCannotEditTheReport() {
        User stranger = user(3L, "orang@demo.id", UserRole.CITIZEN);
        when(userRepository.findByEmail("orang@demo.id")).thenReturn(Optional.of(stranger));

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class,
                () -> service.updateReport(10L, "orang@demo.id", new UpdateReportRequest(), List.of()));

        assertEquals(403, error.getStatusCode().value());
    }

    // ---------------------------------------------------------------- ajukan ulang

    @Test
    void resubmitWithoutDescriptionOrPhotosIsRejected() {
        report.setStatus(ReportStatus.DITOLAK);

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class,
                () -> service.resubmitReport(10L, OWNER_EMAIL, "   ", List.of()));

        assertEquals(400, error.getStatusCode().value());
        assertEquals(ReportStatus.DITOLAK, report.getStatus());
    }

    @Test
    void resubmitReplacesPhotosDeletesOldOnesAndReturnsToReported() {
        report.setStatus(ReportStatus.DITOLAK);
        when(storage.storeReportPhotos(anyList()))
                .thenReturn(List.of("/uploads/reports/x.png", "/uploads/reports/y.png"));

        ReportResponse response =
                service.resubmitReport(10L, OWNER_EMAIL, null, List.of(png("x.png"), png("y.png")));

        assertEquals(ReportStatus.DILAPORKAN, response.getStatus());
        assertEquals(2, response.getPhotoUrls().size());
        verify(storage).deletePhotos(List.of("/uploads/reports/a.jpg", "/uploads/reports/b.jpg"));
    }
}
