package com.laporjalan.dto.response;

import com.laporjalan.model.enums.UserRole;
import lombok.Data;

@Data
public class AuthResponse {
    
    private Long id;
    private String name;
    private String email;
    private UserRole role;
    private String token;
    private String phoneNumber;
    
    public AuthResponse(Long id, String name, String email, UserRole role, String token, String phoneNumber) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.role = role;
        this.token = token;
        this.phoneNumber = phoneNumber;
    }
}
