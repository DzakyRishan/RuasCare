package com.laporjalan.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.laporjalan.model.enums.RejectReason;
import com.laporjalan.model.enums.ReportSeverity;
import com.laporjalan.model.enums.ReportStatus;
import com.laporjalan.model.enums.UserRole;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class ReportResponse {

    private Long id;
    private ReporterInfo reporter;
    private String description;
    private ReportSeverity severity;
    private ReportStatus status;
    private Double latitude;
    private Double longitude;
    private String locationName;
    private List<String> photoUrls;
    private List<String> repairPhotoUrls = List.of();
    private RejectReason rejectReason;
    private String rejectNote;
    @JsonProperty("isMine")
    private boolean mine;
    private List<StatusHistoryItem> statusHistory = List.of();
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    @Data
    public static class ReporterInfo {
        private Long id;
        private String name;
        private String email;
    }

    @Data
    public static class StatusHistoryItem {
        private Long id;
        private ReportStatus fromStatus;
        private ReportStatus toStatus;
        private UserRole changedByRole;
        private String note;
        private LocalDateTime createdAt;
    }
}
