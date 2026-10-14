package com.example.app_spring.auth;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 认证服务。
 *
 * <p>密码按需求以明文入库，登录时直接做字符串等值比较，
 * 全程不做哈希或加密处理。
 */
@Service
public class AuthService {

    private static final String DEFAULT_AVATAR = "assets/images/user-avatar-1.jpg";

    private final UserMapper userMapper;
    private final TokenService tokenService;

    public AuthService(UserMapper userMapper, TokenService tokenService) {
        this.userMapper = userMapper;
        this.tokenService = tokenService;
    }

    @Transactional
    public AuthDtos.AuthResponse register(AuthDtos.RegisterRequest req) {
        final String username = safeTrim(req.username());
        final String password = req == null ? "" : safeTrim(req.password());

        validateUsername(username);
        validatePassword(password);

        if (userMapper.existsByUsername(username)) {
            throw new BadRequestException("用户名已存在");
        }

        final UserEntity saved = UserEntity.newUser(username, password, DEFAULT_AVATAR);
        saved.setLastLoginAtMs(System.currentTimeMillis());
        userMapper.insert(saved);
        return buildResponse(saved);
    }

    @Transactional
    public AuthDtos.AuthResponse login(AuthDtos.LoginRequest req) {
        final String username = safeTrim(req.username());
        final String password = req == null ? "" : safeTrim(req.password());

        if (username.isEmpty()) {
            throw new BadRequestException("请输入用户名");
        }
        if (password.isEmpty()) {
            throw new BadRequestException("请输入密码");
        }

        final UserEntity user = userMapper.findByUsername(username);
        if (user == null) {
            // 账号不存在与密码错误分开提示，便于前端展示
            throw new UnauthorizedException("账号不存在");
        }

        if (user.getStatus() != UserEntity.STATUS_ENABLED) {
            throw new UnauthorizedException("账号已被禁用，请联系管理员");
        }

        // 明文密码直接比对
        if (!user.getPassword().equals(password)) {
            throw new UnauthorizedException("密码错误");
        }

        user.setLastLoginAtMs(System.currentTimeMillis());
        userMapper.updateLastLogin(user.getId(), user.getLastLoginAtMs());
        return buildResponse(user);
    }

    /** 用 token 反查当前登录用户，用于 App 启动时的自动登录。 */
    @Transactional(readOnly = true)
    public AuthDtos.AuthResponse me(String token) {
        final TokenService.TokenPayload payload = tokenService.parse(token);
        if (payload == null) {
            throw new UnauthorizedException("登录已失效，请重新登录");
        }
        final UserEntity user = userMapper.findById(payload.userId());
        if (user == null) {
            throw new UnauthorizedException("登录已失效，请重新登录");
        }

        // 用户被禁用或用户名已变更，一律视为凭证失效
        if (user.getStatus() != UserEntity.STATUS_ENABLED || !user.getUsername().equals(payload.username())) {
            throw new UnauthorizedException("登录已失效，请重新登录");
        }

        // 复用原 token 与剩余有效期，不重新签发，避免 App 每次启动都换票
        return buildResponse(user, token, payload.expiresAtMs());
    }

    private AuthDtos.AuthResponse buildResponse(UserEntity e) {
        final String token = tokenService.issue(e.getId(), e.getUsername());
        final TokenService.TokenPayload payload = tokenService.parse(token);
        return new AuthDtos.AuthResponse(toUser(e), token, payload == null ? 0L : payload.expiresAtMs());
    }

    private AuthDtos.AuthResponse buildResponse(UserEntity e, String token, long expiresAtMs) {
        return new AuthDtos.AuthResponse(toUser(e), token, expiresAtMs);
    }

    private static AuthDtos.AuthUser toUser(UserEntity e) {
        final String nickname = (e.getNickname() == null || e.getNickname().isBlank())
                ? e.getUsername()
                : e.getNickname();
        return new AuthDtos.AuthUser(e.getId(), e.getUsername(), nickname, e.getAvatar(), e.getLastLoginAtMs());
    }

    private static void validateUsername(String username) {
        if (username.isEmpty()) {
            throw new BadRequestException("请输入用户名");
        }
        // token 载荷使用 | 分隔，含 | 会破坏解析，故仅排除该字符
        if (username.indexOf('|') >= 0) {
            throw new BadRequestException("用户名不能包含 | 字符");
        }
    }

    private static void validatePassword(String password) {
        if (password.isEmpty()) {
            throw new BadRequestException("请输入密码");
        }
    }

    private static String safeTrim(String v) {
        return v == null ? "" : v.trim();
    }

    static final class BadRequestException extends RuntimeException {
        BadRequestException(String message) {
            super(message);
        }
    }

    static final class UnauthorizedException extends RuntimeException {
        UnauthorizedException(String message) {
            super(message);
        }
    }
}
