package com.example.app_spring.community;

import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.ArrayList;

@Service
public class CommunityService {

    private final CommunityPostRepository repo;

    public CommunityService(CommunityPostRepository repo) {
        this.repo = repo;
    }

    public List<CommunityPostDto> list() {
        final List<CommunityPostEntity> list = repo.findAllByOrderByCreatedAtMsDesc();
        final List<CommunityPostDto> out = new ArrayList<>(list.size());
        for (final CommunityPostEntity e : list) {
            out.add(toDto(e));
        }
        return out;
    }

    public CommunityPostDto create(String meName, String meAvatar, CreatePostRequest req) {
        final long now = Instant.now().toEpochMilli();

        final List<String> images = req.images() == null ? List.of() : List.copyOf(req.images());

        final CommunityPostEntity e = new CommunityPostEntity();
        e.setUserName(meName);
        e.setUserAvatar(meAvatar);
        e.setContent(req.content());
        e.setTimeAgo("刚刚");
        e.setFeatured(req.featured());
        e.setImages(new ArrayList<>(images));
        e.setLikes(0);
        e.setComments(0);
        e.setLiked(false);
        e.setLikeUsers(new ArrayList<>());
        e.setCreatedAtMs(now);
        return toDto(repo.save(e));
    }

    public CommunityPostDto toggleLike(long id, String meName) {
        final CommunityPostEntity e = repo.findById(id).orElseThrow(() -> new PostNotFoundException(id));

        final boolean currentlyLiked = e.isLiked();
        e.setLiked(!currentlyLiked);
        if (e.isLiked()) {
            e.setLikes(e.getLikes() + 1);
            final List<String> likeUsers = new ArrayList<>(e.getLikeUsers());
            if (!likeUsers.contains(meName)) {
                likeUsers.add(0, meName);
            }
            e.setLikeUsers(likeUsers);
        } else {
            e.setLikes(Math.max(0, e.getLikes() - 1));
            final List<String> likeUsers = new ArrayList<>(e.getLikeUsers());
            likeUsers.remove(meName);
            e.setLikeUsers(likeUsers);
        }

        return toDto(repo.save(e));
    }

    private static CommunityPostDto toDto(CommunityPostEntity e) {
        return new CommunityPostDto(
                e.getId(),
                e.getUserName(),
                e.getUserAvatar(),
                e.getContent(),
                e.getTimeAgo(),
                e.isFeatured(),
                e.getImages() == null ? List.of() : List.copyOf(e.getImages()),
                e.getLikes(),
                e.getComments(),
                e.isLiked(),
                e.getLikeUsers() == null ? List.of() : Collections.unmodifiableList(new ArrayList<>(e.getLikeUsers()))
        );
    }

    static final class PostNotFoundException extends RuntimeException {
        final long id;

        PostNotFoundException(long id) {
            super("post not found: " + id);
            this.id = id;
        }
    }
}
