package com.laporjalan.dto.request;

import com.laporjalan.model.enums.RejectReason;
import com.laporjalan.model.enums.ReportStatus;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdateReportStatusRequest {
    
    @NotNull(message = "New status is required")
    private ReportStatus newStatus;
    
    private RejectReason rejectReason;
    
    private String note;
}
