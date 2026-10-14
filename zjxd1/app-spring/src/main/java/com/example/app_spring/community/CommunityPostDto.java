package com.example.app_spring.community;

import java.util.List;

public record CommunityPostDto(
        long id,
        String userName,
        String userAvatar,
        String content,
        String timeAgo,
        boolean featured,
        List<String> images,
        int likes,
        int comments,
        boolean liked,
        List<String> likeUsers
) {
}
