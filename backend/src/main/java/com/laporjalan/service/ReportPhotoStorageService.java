package com.laporjalan.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class ReportPhotoStorageService {

    private static final int MIN_PHOTO_COUNT = 2;
    private static final int MAX_PHOTO_COUNT = 3;
    private static final long MAX_PHOTO_SIZE_BYTES = 5L * 1024 * 1024;

    private final Path reportPhotoDirectory;

    public ReportPhotoStorageService(@Value("${app.upload.directory:uploads}") String uploadDirectory) {
        reportPhotoDirectory = Paths.get(uploadDirectory)
                .toAbsolutePath()
                .normalize()
                .resolve("reports");
    }

    /** Foto laporan warga: wajib 2-3 foto. */
    public List<String> storeReportPhotos(List<MultipartFile> photos) {
        return storePhotos(photos, MIN_PHOTO_COUNT, MAX_PHOTO_COUNT);
    }

    /** Foto bukti perbaikan dari petugas: wajib 1-3 foto. */
    public List<String> storeRepairPhotos(List<MultipartFile> photos) {
        return storePhotos(photos, 1, MAX_PHOTO_COUNT);
    }

    /**
     * Menyimpan foto dengan batas jumlah yang ditentukan pemanggil. Jika
     * {@code minCount} 0 dan tidak ada foto, hasilnya daftar kosong.
     */
    public List<String> storePhotos(List<MultipartFile> photos, int minCount, int maxCount) {
        if (minCount == 0 && (photos == null || photos.isEmpty())) {
            return List.of();
        }
        validatePhotoCount(photos, minCount, maxCount);
        createDirectoryIfNeeded();

        List<String> storedUrls = new ArrayList<>();
        try {
            for (MultipartFile photo : photos) {
                byte[] bytes = validateAndRead(photo);
                String extension = extensionFor(bytes);
                String fileName = UUID.randomUUID() + "." + extension;
                Path destination = reportPhotoDirectory.resolve(fileName).normalize();
                if (!destination.startsWith(reportPhotoDirectory)) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid photo filename");
                }
                Files.write(destination, bytes);
                storedUrls.add("/uploads/reports/" + fileName);
            }
            return List.copyOf(storedUrls);
        } catch (RuntimeException exception) {
            deletePhotos(storedUrls);
            throw exception;
        } catch (IOException exception) {
            deletePhotos(storedUrls);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to store report photos");
        }
    }

    public void deletePhotos(List<String> photoUrls) {
        for (String photoUrl : photoUrls) {
            // Hanya file yang disimpan server ini; URL eksternal diabaikan.
            if (photoUrl == null || !photoUrl.startsWith("/uploads/reports/")) {
                continue;
            }
            try {
                String fileName = Paths.get(photoUrl).getFileName().toString();
                Path photoPath = reportPhotoDirectory.resolve(fileName).normalize();
                if (photoPath.startsWith(reportPhotoDirectory)) {
                    Files.deleteIfExists(photoPath);
                }
            } catch (IOException | RuntimeException ignored) {
                // Deleting a failed-upload file is best effort.
            }
        }
    }

    private void validatePhotoCount(List<MultipartFile> photos, int minCount, int maxCount) {
        if (photos == null || photos.size() < minCount || photos.size() > maxCount) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Provide between " + minCount + " and " + maxCount + " photos");
        }
    }

    private void createDirectoryIfNeeded() {
        try {
            Files.createDirectories(reportPhotoDirectory);
        } catch (IOException exception) {
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Upload directory is unavailable");
        }
    }

    private byte[] validateAndRead(MultipartFile photo) throws IOException {
        if (photo == null || photo.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Each photo must contain image data");
        }
        if (photo.getSize() > MAX_PHOTO_SIZE_BYTES) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Each photo must be 5 MB or smaller");
        }

        byte[] bytes = photo.getBytes();
        if (!isJpeg(bytes) && !isPng(bytes) && !isWebp(bytes)) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Only JPEG, PNG, or WEBP image files are allowed");
        }
        return bytes;
    }

    private String extensionFor(byte[] bytes) {
        if (isJpeg(bytes)) return "jpg";
        if (isPng(bytes)) return "png";
        return "webp";
    }

    private boolean isJpeg(byte[] bytes) {
        return bytes.length >= 3
                && (bytes[0] & 0xFF) == 0xFF
                && (bytes[1] & 0xFF) == 0xD8
                && (bytes[2] & 0xFF) == 0xFF;
    }

    private boolean isPng(byte[] bytes) {
        return bytes.length >= 8
                && (bytes[0] & 0xFF) == 0x89
                && bytes[1] == 0x50
                && bytes[2] == 0x4E
                && bytes[3] == 0x47
                && bytes[4] == 0x0D
                && bytes[5] == 0x0A
                && bytes[6] == 0x1A
                && bytes[7] == 0x0A;
    }

    private boolean isWebp(byte[] bytes) {
        return bytes.length >= 12
                && bytes[0] == 'R'
                && bytes[1] == 'I'
                && bytes[2] == 'F'
                && bytes[3] == 'F'
                && bytes[8] == 'W'
                && bytes[9] == 'E'
                && bytes[10] == 'B'
                && bytes[11] == 'P';
    }
}
