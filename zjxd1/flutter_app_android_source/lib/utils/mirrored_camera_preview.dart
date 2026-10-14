import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class MirroredCameraPreview extends StatelessWidget {
  const MirroredCameraPreview({
    super.key,
    required this.controller,
    this.mirror = true,
  });

  final CameraController controller;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final preview = CameraPreview(controller);
    
    // 根据mirror参数决定是否镜像翻转，默认镜像
    if (mirror) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
        child: preview,
      );
    } else {
      return preview;
    }
  }
}
