package com.laporjalan.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ReportPhotoStorageServiceTest {

    private static final byte[] PNG_BYTES = new byte[] {
            (byte) 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00
    };

    @TempDir
    Path temporaryDirectory;

    @Test
    void storesTwoValidPhotosWithSafeGeneratedNames() throws Exception {
        ReportPhotoStorageService storageService =
                new ReportPhotoStorageService(temporaryDirectory.toString());

        List<String> storedUrls = storageService.storeReportPhotos(List.of(
                pngPhoto("jalan-depan.jpg"),
                pngPhoto("../../tidak-aman.png")));

        assertEquals(2, storedUrls.size());
        for (String storedUrl : storedUrls) {
            assertTrue(storedUrl.startsWith("/uploads/reports/"));
            String fileName = Path.of(storedUrl).getFileName().toString();
            assertTrue(Files.exists(temporaryDirectory.resolve("reports").resolve(fileName)));
        }

        storageService.deletePhotos(storedUrls);
        assertEquals(0, Files.list(temporaryDirectory.resolve("reports")).count());
    }

    @Test
    void rejectsTooFewPhotos() {
        ReportPhotoStorageService storageService =
                new ReportPhotoStorageService(temporaryDirectory.toString());

        assertThrows(
                RuntimeException.class,
                () -> storageService.storeReportPhotos(List.of(pngPhoto("satu.png"))));
    }

    @Test
    void rejectsNonImageContentRegardlessOfFileExtension() {
        ReportPhotoStorageService storageService =
                new ReportPhotoStorageService(temporaryDirectory.toString());
        MockMultipartFile invalidPhoto = new MockMultipartFile(
                "photos",
                "bukan-foto.jpg",
                "image/jpeg",
                "teks biasa".getBytes());

        assertThrows(
                RuntimeException.class,
                () -> storageService.storeReportPhotos(List.of(
                        invalidPhoto,
                        pngPhoto("foto-valid.png"))));
    }

    private MockMultipartFile pngPhoto(String originalFileName) {
        return new MockMultipartFile(
                "photos",
                originalFileName,
                "image/png",
                PNG_BYTES);
    }
}
