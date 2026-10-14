package com.example.app_spring.motion;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

/** 运动记录：训练完成上报保存，运动记录页按用户查询 */
@RestController
@RequestMapping("/api/motion")
public class MotionRecordController {

    private final MotionRecordRepository repo;

    public MotionRecordController(MotionRecordRepository repo) {
        this.repo = repo;
    }

    /** 训练完成保存一条运动记录 */
    @PostMapping("/save")
    @ResponseStatus(HttpStatus.CREATED)
    public Map<String, Object> save(
            @RequestParam(value = "username", required = false) String username,
            @RequestBody MotionRecordDto dto) {
        final String user = (username == null || username.isBlank()) ? "anonymous" : username.trim();
        final MotionRecordEntity saved = repo.save(new MotionRecordEntity(user, dto));
        return Map.of("message", "保存成功", "id", saved.getId());
    }

    /** 查询用户运动记录（最新在前） */
    @GetMapping("/list")
    public List<MotionRecordDto> list(@RequestParam(value = "username", required = false) String username) {
        final String user = (username == null || username.isBlank()) ? "" : username.trim();
        return repo.findRecords(user).stream()
                .map(e -> new MotionRecordDto(
                        e.getMotionName(),
                        e.getActualCount(),
                        e.getTargetCount(),
                        e.getActualTimeSeconds(),
                        e.isCountMode(),
                        e.getCreatedAtMs()
                ))
                .toList();
    }
}