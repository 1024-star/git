package com.example.app_spring.auth;

public final class AuthDtos {
    private AuthDtos() {
    }

    public record RegisterRequest(String username, String password) {
    }

    public record LoginRequest(String username, String password) {
    }

    public record AuthUser(long id, String username, String nickname, String avatar, Long lastLoginAtMs) {
    }

    public record AuthResponse(AuthUser user, String token, long expiresAtMs) {
    }
}
