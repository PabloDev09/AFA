import 'package:afa/design/screens/loading_no_child_screen.dart';
import 'package:flutter/material.dart';

class DelayedService extends StatefulWidget {
  final Widget screen;
  final Duration delay;

  const DelayedService({
    super.key,
    required this.screen,
    this.delay = const Duration(seconds: 3),
  });

  @override
  State<DelayedService> createState() => _DelayedServiceState();
}

class _DelayedServiceState extends State<DelayedService> {
  bool _showScreen = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _showScreen = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showScreen ? widget.screen : const LoadingNoChildScreen();
  }
}
