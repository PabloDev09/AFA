import 'package:afa/design/screens/login_screen.dart';
import 'package:afa/design/screens/not_found_screen.dart';
import 'package:afa/design/screens/register_screen.dart';
import 'package:afa/design/screens/welcome_screen.dart';
import 'package:afa/logic/router/services/auth_loader_service.dart';
import 'package:afa/logic/router/services/delayed_service.dart';
import 'package:afa/logic/router/services/navigator_service.dart';
import 'package:afa/logic/router/services/role_based_home_service.dart';
import 'package:afa/logic/router/services/role_based_settings_service.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

Future<String?> getUserRole() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final userService = UserService();
  return await userService.getUserRoleByEmail(user.email!);
}

bool isAuthenticated() {
  return FirebaseAuth.instance.currentUser != null;
}


final GoRouter afaRouter = GoRouter(
  navigatorKey: NavigatorService.navigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = isAuthenticated();
    final goingToPublic = [
      '/',
      '/login',
      '/register',
    ].contains(state.matchedLocation);

    if (!isLoggedIn && !goingToPublic) return '/login';
    if (isLoggedIn && state.matchedLocation == '/login') return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'welcome',
      builder: (context, state) =>
          const DelayedService(screen: WelcomeScreen()),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) =>
          const DelayedService(screen: LoginScreen()),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) =>
          const DelayedService(screen: RegisterScreen()),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const AuthLoaderService(
        child: RoleBasedHomeService(),
      ),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const AuthLoaderService(
        child: RoleBasedSettingsService(),
      ),
    ),
  ],
  errorBuilder: (context, state) => const DelayedService(
    screen: NotFoundScreen(),
  ),
);
