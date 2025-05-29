import 'package:afa/design/screens/dashboard_screen.dart';
import 'package:afa/design/screens/driver_home_screen.dart';
import 'package:afa/design/screens/loading_no_child_screen.dart';
import 'package:afa/design/screens/login_screen.dart';
import 'package:afa/design/screens/map_screen.dart';
import 'package:afa/design/screens/not_found_screen.dart';
import 'package:afa/design/screens/notice_board_screen.dart';
import 'package:afa/design/screens/notice_board_screen.dart';
import 'package:afa/design/screens/register_screen.dart';
import 'package:afa/design/screens/settings_screen.dart';
import 'package:afa/design/screens/user_home_screen.dart';
import 'package:afa/design/screens/welcome_screen.dart';
import 'package:afa/logic/router/services/navigator_service.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

Widget _buildWithLoading(BuildContext context, Widget screen,
    {Duration delay = const Duration(seconds: 3)}) {
  return FutureBuilder(
    future: Future.delayed(delay),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        return screen;
      }
      return const LoadingNoChildScreen();
    },
  );
}

final GoRouter afaRouter = GoRouter(
  navigatorKey: NavigatorService.navigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = isAuthenticated();
    final goingToPublic = state.matchedLocation == '/' || state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (!isLoggedIn && !goingToPublic) {
      return '/login'; 
    }

    if (isLoggedIn && state.matchedLocation == '/login') {
      return '/home'; 
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      name: 'welcome',
      builder: (context, state) => _buildWithLoading(
        context,
        const WelcomeScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => _buildWithLoading(
        context,
        const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => _buildWithLoading(
        context,
        const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => FutureBuilder<String?>(
        future: getUserRole(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingNoChildScreen();
          }
          final role = snapshot.data;
          Widget targetScreen;
          if (role == 'Usuario') {
            targetScreen = const UserHomeScreen();
          } else if (role == 'Conductor') {
            targetScreen = const DriverHomeScreen();
          } else if (role == 'Administrador') {
            targetScreen = const DashboardScreen();
          } else {
            targetScreen = const LoadingNoChildScreen();
          }
          return _buildWithLoading(
            context,
            targetScreen,
            delay: const Duration(seconds: 3),
          );
        },
      ),
    ),
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (context, state) => FutureBuilder<String?>(
        future: getUserRole(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingNoChildScreen();
          }
          final role = snapshot.data;
          if (role == 'Usuario' || role == 'Conductor') {
            return _buildWithLoading(
              context,
              const MapScreen(),
              delay: const Duration(seconds: 3),
            );
          }
          return const LoadingNoChildScreen();
        },
      ),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => FutureBuilder<String?>(
        future: getUserRole(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingNoChildScreen();
          }
          final role = snapshot.data;
          if (role == 'Usuario' ||
              role == 'Conductor' ||
              role == 'Administrador') {
            return _buildWithLoading(
              context,
              const SettingsScreen(),
              delay: const Duration(seconds: 3),
            );
          }
          return const LoadingNoChildScreen();
        },
      ),
    ),
    GoRoute(
      path: '/noticeboard',
      name: 'noticeboard',
      builder: (context, state) => FutureBuilder<String?>(
        future: getUserRole(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingNoChildScreen();
          }
          final role = snapshot.data;
          if (role == 'Usuario' ||
              role == 'Conductor' ||
              role == 'Administrador') {
            return _buildWithLoading(
              context,
              const NoticeBoardScreen(),
              delay: const Duration(seconds: 3),
            );
          }
          return const LoadingNoChildScreen();
        },
      ),
    ),
  ],
  errorBuilder: (context, state) => FutureBuilder(
    future: Future.delayed(const Duration(seconds: 3)),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const LoadingNoChildScreen();
      }
      return const NotFoundScreen();
    },
  ),
);
