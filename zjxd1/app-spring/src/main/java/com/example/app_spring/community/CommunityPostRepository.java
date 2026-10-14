package com.example.app_spring.community;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CommunityPostRepository extends JpaRepository<CommunityPostEntity, Long> {
    List<CommunityPostEntity> findAllByOrderByCreatedAtMsDesc();
}
