package com.example.app_spring.auth;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 用户表 Mapper（MyBatis）。
 *
 * <p>SQL 语句全部维护在 src/main/resources/mapper/UserMapper.xml 中。
 */
@Mapper
public interface UserMapper {

    /** 仅按用户名精确匹配，密码是否正确由 Service 层的明文比对决定。 */
    UserEntity findByUsername(@Param("username") String username);

    /** 按主键查询。 */
    UserEntity findById(@Param("id") Long id);

    /** 判断用户名是否已存在。 */
    boolean existsByUsername(@Param("username") String username);

    /** 插入新用户，写入数据库自增主键。 */
    int insert(UserEntity user);

    /** 更新用户的最近登录时间。 */
    int updateLastLogin(@Param("id") Long id, @Param("lastLoginAtMs") Long lastLoginAtMs);
}