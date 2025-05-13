import 'package:flutter/material.dart';

class AfaGifController
{
  final TickerProvider vsync;
  final int frameCount;
  final int fps;
  late AnimationController animationController;
  late Animation<int> _frameAnimation;

  AfaGifController
  ({
    required this.vsync,
    required this.frameCount,
    required this.fps,
  })
  {
    animationController = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: (frameCount * 1000 / fps).round()),
    )..repeat();

    _frameAnimation = IntTween(begin: 0, end: frameCount - 1).animate(animationController);
  }

  int get currentFrame => _frameAnimation.value;

  void dispose()
  {
    animationController.dispose();
  }
}
