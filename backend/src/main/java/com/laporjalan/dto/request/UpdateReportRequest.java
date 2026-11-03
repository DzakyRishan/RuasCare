package com.laporjalan.dto.request;

import com.laporjalan.model.enums.ReportSeverity;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

/**
 * Perubahan laporan oleh warga pemilik. Foto baru dikirim terpisah sebagai
 * multipart; {@code keepPhotoUrls} berisi foto lama yang tetap dipakai.
 */
@Data
public class UpdateReportRequest {

    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    private String description;

    private ReportSeverity severity;

    private Double latitude;

    private Double longitude;

    @Size(max = 255, message = "Location name must not exceed 255 characters")
    private String locationName;

    /** Null berarti foto tidak diubah. */
    private List<String> keepPhotoUrls;
}
