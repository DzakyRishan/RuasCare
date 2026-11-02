package com.laporjalan.dto.request;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

@Data
public class ResubmitReportRequest {

    @Size(max = 1000, message = "Description must not exceed 1000 characters")
    private String description;

    @Size(min = 2, max = 3, message = "Must provide 2-3 photos when replacing photos")
    private List<String> photoUrls;

    @AssertTrue(message = "Provide a new description or 2-3 replacement photos")
    public boolean isNewContentProvided() {
        return (description != null && !description.trim().isEmpty())
                || (photoUrls != null && !photoUrls.isEmpty());
    }
}
