// 临时入口：直接打开臀桥 AI 训练页，用于验证「相机 -> 抽帧 -> PC识别 -> 骨骼叠加」链路
import 'package:flutter/material.dart';
import 'features/training/hip_bridge/hip_bridge_ai_training_page.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HipBridgeAiTrainingPage(targetReps: 3, levelName: '臀桥训练(联调)'),
  ));
}