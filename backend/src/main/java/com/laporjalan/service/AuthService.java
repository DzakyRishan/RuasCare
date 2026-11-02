package com.laporjalan.service;

import com.laporjalan.dto.request.LoginRequest;
import com.laporjalan.dto.request.RegisterRequest;
import com.laporjalan.dto.response.AuthResponse;
import com.laporjalan.model.entity.User;
import com.laporjalan.model.enums.UserRole;
import com.laporjalan.repository.UserRepository;
import com.laporjalan.security.JwtUtils;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.Locale;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;

    public AuthService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtUtils jwtUtils) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtils = jwtUtils;
    }

    public AuthResponse register(RegisterRequest request) {
        String email = request.getEmail().trim().toLowerCase(Locale.ROOT);
        if (userRepository.existsByEmail(email)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already exists");
        }

        User user = new User();
        user.setName(request.getName().trim());
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        // Public registration can never grant privileged access.
        user.setRole(UserRole.CITIZEN);
        user.setPhoneNumber(request.getPhoneNumber());

        return createAuthResponse(userRepository.save(user), true);
    }

    public AuthResponse login(LoginRequest request) {
        String email = request.getEmail().trim().toLowerCase(Locale.ROOT);
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid email or password");
        }

        return createAuthResponse(user, true);
    }

    public AuthResponse getCurrentUser(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
        return createAuthResponse(user, false);
    }

    private AuthResponse createAuthResponse(User user, boolean includeToken) {
        String token = includeToken
                ? jwtUtils.generateToken(user.getEmail(), user.getRole().name())
                : null;
        return new AuthResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getRole(),
                token,
                user.getPhoneNumber());
    }
}
