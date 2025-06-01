import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/design/screens/loading_no_child_screen.dart';

class AuthLoaderService extends StatefulWidget {
  final Widget child;
  const AuthLoaderService({super.key, required this.child});

  @override
  _AuthLoaderState createState() => _AuthLoaderState();
}

class _AuthLoaderState extends State<AuthLoaderService> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Provider.of<AuthUserProvider>(context, listen: false).loadUser();
    if (mounted) {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) {
      return const LoadingNoChildScreen();
    }
    return widget.child;
  }
}
