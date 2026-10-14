package com.example.app_spring.community;

import java.util.List;

public record CreatePostRequest(
        String content,
        boolean featured,
        List<String> images
) {
}
