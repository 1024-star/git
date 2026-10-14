package com.example.app_spring.community;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Component
public class CommunitySeeder implements ApplicationRunner {

    private final CommunityPostRepository repo;

    public CommunitySeeder(CommunityPostRepository repo) {
        this.repo = repo;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (repo.count() > 0) return;

        final long now = Instant.now().toEpochMilli();

        repo.save(newPost(
                "健身小达人",
                "assets/images/user-avatar-2.jpg",
                "今天完成了30分钟的臀桥训练，感觉核心力量提升了很多！大家也要坚持运动哦~ 💪",
                "5分钟前",
                true,
                List.of("assets/images/hip-bridge-1.png"),
                24,
                8,
                true,
                new ArrayList<>(List.of("小恐龙", "运动女孩", "健康生活")),
                now - 5 * 60 * 1000L
        ));

        repo.save(newPost(
                "瑜伽小仙女",
                "assets/images/user-avatar-3.png",
                "晨练瑜伽结束！今天的拉伸让身体特别舒服，推荐给大家这组动作~ ✨",
                "1小时前",
                false,
                List.of("assets/images/side-plank-support.png", "assets/images/balance-training.png"),
                18,
                5,
                false,
                new ArrayList<>(List.of("运动达人", "健康女孩")),
                now - 60 * 60 * 1000L
        ));

        repo.save(newPost(
                "跑步爱好者",
                "assets/images/user-avatar-4.jpg",
                "完成今天的5公里跑步！天气很好，心情也很棒~ 🌞",
                "2小时前",
                false,
                List.of("assets/images/jinggangshan.png"),
                32,
                12,
                true,
                new ArrayList<>(List.of("小恐龙", "健身小达人", "运动女孩", "跑步小子")),
                now - 2 * 60 * 60 * 1000L
        ));
    }

    private static CommunityPostEntity newPost(
            String userName,
            String userAvatar,
            String content,
            String timeAgo,
            boolean featured,
            List<String> images,
            int likes,
            int comments,
            boolean liked,
            List<String> likeUsers,
            long createdAtMs
    ) {
        final CommunityPostEntity e = new CommunityPostEntity();
        e.setUserName(userName);
        e.setUserAvatar(userAvatar);
        e.setContent(content);
        e.setTimeAgo(timeAgo);
        e.setFeatured(featured);
        e.setImages(new ArrayList<>(images));
        e.setLikes(likes);
        e.setComments(comments);
        e.setLiked(liked);
        e.setLikeUsers(likeUsers);
        e.setCreatedAtMs(createdAtMs);
        return e;
    }
}
