package com.example.app_spring.motion;

public record MotionRecordDto(
        String motionName,
        Integer actualCount,
        Integer targetCount,
        Integer actualTimeSeconds,
        Boolean isCountMode,
        Long createdAtMs
) {
    public int actualCountValue() {
        return actualCount == null ? 0 : actualCount;
    }

    public int targetCountValue() {
        return targetCount == null ? 0 : targetCount;
    }

    public int actualTimeSecondsValue() {
        return actualTimeSeconds == null ? 0 : actualTimeSeconds;
    }

    public boolean isCountModeValue() {
        return isCountMode != null && isCountMode;
    }
}