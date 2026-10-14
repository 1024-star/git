package com.example.app_spring.auth;

/**
 * 用户实体（MyBatis POJO）。
 *
 * <p>仅作为数据库 users 表的一行映射，不再承载任何 ORM 注解；
 * 查询由 {@link UserMapper} 负责，密码为明文存储。
 */
public class UserEntity {

    /** 账号状态：正常 */
    public static final int STATUS_ENABLED = 1;
    /** 账号状态：禁用 */
    public static final int STATUS_DISABLED = 0;

    private Long id;
    private String username;
    private String password;
    private String nickname;
    private String avatar;
    private int status;
    private long createdAtMs;
    private Long lastLoginAtMs;

    public UserEntity() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getNickname() {
        return nickname;
    }

    public void setNickname(String nickname) {
        this.nickname = nickname;
    }

    public String getAvatar() {
        return avatar;
    }

    public void setAvatar(String avatar) {
        this.avatar = avatar;
    }

    public int getStatus() {
        return status;
    }

    public void setStatus(int status) {
        this.status = status;
    }

    public long getCreatedAtMs() {
        return createdAtMs;
    }

    public void setCreatedAtMs(long createdAtMs) {
        this.createdAtMs = createdAtMs;
    }

    public Long getLastLoginAtMs() {
        return lastLoginAtMs;
    }

    public void setLastLoginAtMs(Long lastLoginAtMs) {
        this.lastLoginAtMs = lastLoginAtMs;
    }

    public static UserEntity newUser(String username, String password, String avatar) {
        final UserEntity u = new UserEntity();
        u.setUsername(username);
        u.setPassword(password);
        u.setAvatar(avatar);
        u.setStatus(STATUS_ENABLED);
        u.setCreatedAtMs(System.currentTimeMillis());
        u.setLastLoginAtMs(null);
        return u;
    }
}