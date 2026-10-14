package com.example.app_spring.profile;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserProfileArchiveRepository extends JpaRepository<UserProfileArchiveEntity, Long> {

    /** 按用户名查询个性化档案（用户名唯一） */
    Optional<UserProfileArchiveEntity> findFirstByUsername(String username);
}
