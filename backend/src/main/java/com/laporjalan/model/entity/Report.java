package com.laporjalan.model.entity;

import com.laporjalan.model.enums.RejectReason;
import com.laporjalan.model.enums.ReportSeverity;
import com.laporjalan.model.enums.ReportStatus;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.annotations.Type;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "reports")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Report {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reporter_id", nullable = false)
    private User reporter;

    @Column(nullable = false, length = 1000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ReportSeverity severity;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ReportStatus status = ReportStatus.DILAPORKAN;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(name = "location_name")
    private String locationName;

    @Column(name = "photo_urls", columnDefinition = "TEXT[]")
    private String[] photoUrls;

    /** Foto bukti perbaikan yang diunggah petugas saat status Diperbaiki. */
    @Column(name = "repair_photo_urls", columnDefinition = "TEXT[]")
    private String[] repairPhotoUrls;

    @Enumerated(EnumType.STRING)
    @Column(name = "reject_reason")
    private RejectReason rejectReason;

    @Column(name = "reject_note", length = 500)
    private String rejectNote;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    // Explicit getters/setters (Lombok fallback)
    public User getReporter() {
        return reporter;
    }

    public void setReporter(User reporter) {
        this.reporter = reporter;
    }
}
