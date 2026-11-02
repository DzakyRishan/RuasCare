package com.laporjalan.repository;

import com.laporjalan.model.entity.ReportStatusLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReportStatusLogRepository extends JpaRepository<ReportStatusLog, Long> {
    List<ReportStatusLog> findByReportIdOrderByCreatedAtDesc(Long reportId);

    List<ReportStatusLog> findByReportIdOrderByCreatedAtAsc(Long reportId);
}
