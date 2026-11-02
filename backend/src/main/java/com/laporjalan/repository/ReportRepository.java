package com.laporjalan.repository;

import com.laporjalan.model.entity.Report;
import com.laporjalan.model.enums.ReportSeverity;
import com.laporjalan.model.enums.ReportStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReportRepository extends JpaRepository<Report, Long> {
    
    List<Report> findByReporterId(Long reporterId);
    
    List<Report> findByStatus(ReportStatus status);
    
    List<Report> findBySeverity(ReportSeverity severity);
    
    List<Report> findByStatusAndSeverity(ReportStatus status, ReportSeverity severity);
    
    @Query(value = "SELECT * FROM reports WHERE " +
            "ST_DWithin(ST_MakePoint(longitude, latitude)::geography, " +
            "ST_MakePoint(:longitude, :latitude)::geography, :radiusMeters)",
            nativeQuery = true)
    List<Report> findNearbyReports(@Param("latitude") Double latitude, 
                                    @Param("longitude") Double longitude, 
                                    @Param("radiusMeters") Double radiusMeters);
}
