package com.laporjalan.model.entity;

import com.laporjalan.model.enums.ReportStatus;
import com.laporjalan.model.enums.UserRole;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "report_status_logs")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ReportStatusLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "report_id", nullable = false)
    private Report report;

    @Enumerated(EnumType.STRING)
    @Column(name = "from_status")
    private ReportStatus fromStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "to_status", nullable = false)
    private ReportStatus toStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "changed_by_role", nullable = false)
    private UserRole changedByRole;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "changed_by_user_id")
    private User changedByUser;

    @Column(length = 500)
    private String note;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
