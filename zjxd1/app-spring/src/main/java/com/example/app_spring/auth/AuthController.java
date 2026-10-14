package com.example.app_spring.auth;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private static final String BEARER_PREFIX = "Bearer ";

    private final AuthService service;

    public AuthController(AuthService service) {
        this.service = service;
    }

    /** 注册并直接返回登录态（前端注册成功后无需再调一次登录）。 */
    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public AuthDtos.AuthResponse register(@RequestBody AuthDtos.RegisterRequest req) {
        return service.register(req);
    }

    /** 登录，密码在数据库中明文存储，直接等值比对。 */
    @PostMapping("/login")
    public AuthDtos.AuthResponse login(@RequestBody AuthDtos.LoginRequest req) {
        return service.login(req);
    }

    /**
     * 校验当前 token 并换取用户信息，用于 App 冷启动时的自动登录。
     * 请求头：Authorization: Bearer &lt;token&gt;
     */
    @GetMapping("/me")
    public AuthDtos.AuthResponse me(@RequestHeader(value = "Authorization", required = false) String authorization) {
        return service.me(extractToken(authorization));
    }

    /**
     * 退出登录。token 本身无状态，服务端无需维护会话，
     * 这里仅作语义端点，客户端收到 200 后清除本地凭证即可。
     */
    @PostMapping("/logout")
    public Map<String, Object> logout() {
        return Map.of("message", "已退出登录");
    }

    private static String extractToken(String authorization) {
        if (authorization == null || authorization.isBlank()) {
            return "";
        }
        if (authorization.regionMatches(true, 0, BEARER_PREFIX, 0, BEARER_PREFIX.length())) {
            return authorization.substring(BEARER_PREFIX.length()).trim();
        }
        return authorization.trim();
    }

    @ExceptionHandler(AuthService.BadRequestException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Map<String, Object> handleBadRequest(AuthService.BadRequestException e) {
        return Map.of("message", e.getMessage());
    }

    @ExceptionHandler(AuthService.UnauthorizedException.class)
    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    public Map<String, Object> handleUnauthorized(AuthService.UnauthorizedException e) {
        return Map.of("message", e.getMessage());
    }
}
