import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigatorService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static void goToLoginWithMessage() {
    final ctx = context;
    if (ctx == null) return;

    final router = GoRouter.of(ctx);
    final location = router.routerDelegate.currentConfiguration.uri.toString();

    if (!location.contains('/register') && !location.contains('/welcome')) {
      ctx.go('/login');

      Future.delayed(const Duration(seconds: 3), () {
        final loginContext = navigatorKey.currentContext;
        if (loginContext != null) {
          ScaffoldMessenger.of(loginContext).showSnackBar(
            const SnackBar(
              content: Text('Su sesión no está actualizada. Por razones de seguridad, debe volver a autenticarse.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }
}
