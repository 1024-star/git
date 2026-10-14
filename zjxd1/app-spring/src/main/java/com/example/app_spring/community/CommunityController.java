package com.example.app_spring.community;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/community")
public class CommunityController {

    private final CommunityService service;

    public CommunityController(CommunityService service) {
        this.service = service;
    }

    @GetMapping("/posts")
    public List<CommunityPostDto> listPosts() {
        return service.list();
    }

    @PostMapping("/posts")
    @ResponseStatus(HttpStatus.CREATED)
    public CommunityPostDto createPost(
            @RequestHeader(value = "X-User-Name", required = false) String userName,
            @RequestHeader(value = "X-User-Avatar", required = false) String userAvatar,
            @RequestBody CreatePostRequest req
    ) {
        final String meName = (userName == null || userName.isBlank()) ? "小恐龙" : userName;
        final String meAvatar = (userAvatar == null || userAvatar.isBlank()) ? "assets/images/user-avatar-1.jpg" : userAvatar;
        return service.create(meName, meAvatar, req);
    }

    @PostMapping("/posts/{id}/like")
    public CommunityPostDto toggleLike(
            @PathVariable("id") long id,
            @RequestHeader(value = "X-User-Name", required = false) String userName
    ) {
        final String meName = (userName == null || userName.isBlank()) ? "小恐龙" : userName;
        return service.toggleLike(id, meName);
    }

    @ExceptionHandler(CommunityService.PostNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public Map<String, Object> handleNotFound(CommunityService.PostNotFoundException e) {
        return Map.of(
                "message", e.getMessage(),
                "id", e.id
        );
    }
}
