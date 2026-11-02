package com.laporjalan.dto.request;

import com.laporjalan.model.enums.ReportSeverity;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

@Data
public class UpdateReportRequest {
    
    private String description;
    
    private ReportSeverity severity;
    
    private Double latitude;
    
    private Double longitude;
    
    private String locationName;
    
    @Size(min = 2, max = 3, message = "Must provide 2-3 photos")
    private List<String> photoUrls;
}
