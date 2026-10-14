package com.example.app_spring.auth;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;

/**
 * 登录凭证服务。
 *
 * <p>旧实现把 {@code id:username:时间戳} 做一次 Base64 就当作 token，
 * 既没有签名也没有有效期，任何人都能伪造任意用户的身份。这里改为
 * HMAC-SHA256 签名 token：无状态、服务端无需存表，但不可伪造、可校验过期。
 *
 * <p>token 结构：{@code base64url(payload) + "." + base64url(hmacSha256(payload))}
 * payload 内部为 {@code 用户ID|用户名|过期时间戳}，用户名注册时已限制为
 * 字母/数字/下划线，不会与分隔符冲突。
 */
@Service
public class TokenService {

    private static final String HMAC_ALGORITHM = "HmacSHA256";
    private static final char PAYLOAD_SEPARATOR = '|';

    private final byte[] secretKey;
    private final long ttlMs;

    public TokenService(
            @Value("${app.auth.token-secret}") String tokenSecret,
            @Value("${app.auth.token-ttl-hours}") long tokenTtlHours) {
        final byte[] raw = tokenSecret.getBytes(StandardCharsets.UTF_8);
        // 密钥过短时做一次 SHA-256 拉伸，保证 HMAC 输入长度合理
        this.secretKey = raw.length >= 16 ? raw : sha256(raw);
        this.ttlMs = Math.max(1L, tokenTtlHours) * 60L * 60L * 1000L;
    }

    /** 签发一个带有效期的签名 token。 */
    public String issue(long userId, String username) {
        final long expiresAtMs = System.currentTimeMillis() + ttlMs;
        final String payload = userId + PAYLOAD_SEPARATOR + username + PAYLOAD_SEPARATOR + expiresAtMs;
        return encode(payload) + "." + sign(payload);
    }

    /**
     * 解析并校验 token。
     *
     * @return 校验通过返回载荷，签名错误/格式错误/已过期均返回 {@code null}
     */
    public TokenPayload parse(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }
        final int dot = token.indexOf('.');
        if (dot <= 0 || dot == token.length() - 1) {
            return null;
        }

        final String payload;
        try {
            payload = new String(Base64.getUrlDecoder().decode(token.substring(0, dot)), StandardCharsets.UTF_8);
        } catch (IllegalArgumentException e) {
            return null;
        }

        // 先比签名再解析内容，避免处理伪造数据
        if (!MessageDigest.isEqual(
                sign(payload).getBytes(StandardCharsets.UTF_8),
                token.substring(dot + 1).getBytes(StandardCharsets.UTF_8))) {
            return null;
        }

        final String[] parts = payload.split("\\|", 3);
        if (parts.length != 3) {
            return null;
        }

        final long userId;
        final long expiresAtMs;
        try {
            userId = Long.parseLong(parts[0]);
            expiresAtMs = Long.parseLong(parts[2]);
        } catch (NumberFormatException e) {
            return null;
        }

        if (System.currentTimeMillis() > expiresAtMs) {
            return null;
        }
        return new TokenPayload(userId, parts[1], expiresAtMs);
    }

    public record TokenPayload(long userId, String username, long expiresAtMs) {
    }

    private String sign(String payload) {
        final Mac mac;
        try {
            mac = Mac.getInstance(HMAC_ALGORITHM);
            mac.init(new SecretKeySpec(secretKey, HMAC_ALGORITHM));
        } catch (Exception e) {
            throw new IllegalStateException("无法初始化 HMAC 签名器", e);
        }
        return Base64.getUrlEncoder().withoutPadding()
                .encodeToString(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
    }

    private static String encode(String payload) {
        return Base64.getUrlEncoder().withoutPadding()
                .encodeToString(payload.getBytes(StandardCharsets.UTF_8));
    }

    private static byte[] sha256(byte[] input) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(input);
        } catch (Exception e) {
            throw new IllegalStateException("SHA-256 不可用", e);
        }
    }
}
