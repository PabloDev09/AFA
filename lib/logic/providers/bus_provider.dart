import 'package:flutter/material.dart';

class BusProvider extends ChangeNotifier {
  double busProgress = 0.0;
  AnimationController? _controller;

  void resetPosition() {
    busProgress = 0.0;
    notifyListeners();
  }

  void startAnimation(TickerProvider vsync) {
    stopAnimation();
    _controller = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        busProgress = _controller!.value;
        notifyListeners();
      });

    _controller!.repeat();
  }

  void stopAnimation() {
    _controller?.dispose();
    _controller = null;
  }
}
