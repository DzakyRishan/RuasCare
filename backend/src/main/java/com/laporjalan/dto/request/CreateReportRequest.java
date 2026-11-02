package com.laporjalan.dto.request;

import com.laporjalan.model.enums.ReportSeverity;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

@Data
public class CreateReportRequest {
    
    @NotBlank(message = "Description is required")
    private String description;
    
    @NotNull(message = "Severity is required")
    private ReportSeverity severity;
    
    @NotNull(message = "Latitude is required")
    private Double latitude;
    
    @NotNull(message = "Longitude is required")
    private Double longitude;
    
    private String locationName;
    
    private String reporterName;
    
    @NotNull(message = "Photo URLs are required")
    @Size(min = 2, max = 3, message = "Must provide 2-3 photos")
    private List<String> photoUrls;
}
