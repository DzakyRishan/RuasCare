package com.laporjalan.controller;

import com.laporjalan.dto.request.LoginRequest;
import com.laporjalan.dto.request.RegisterRequest;
import com.laporjalan.dto.response.AuthResponse;
import com.laporjalan.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @GetMapping("/me")
    public ResponseEntity<AuthResponse> me(@AuthenticationPrincipal UserDetails userDetails) {
        return ResponseEntity.ok(authService.getCurrentUser(userDetails.getUsername()));
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout() {
        // JWTs are stateless. The client removes its token after this acknowledgement.
        return ResponseEntity.noContent().build();
    }
}
