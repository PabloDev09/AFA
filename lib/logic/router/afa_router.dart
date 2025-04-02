import 'package:afa/design/screens/dashboard_screen.dart';
import 'package:afa/design/screens/driver_home_screen.dart';
import 'package:afa/design/screens/login_screen.dart';
import 'package:afa/design/screens/map_screen.dart';
import 'package:afa/design/screens/not_found_screen.dart';
import 'package:afa/design/screens/register_screen.dart';
import 'package:afa/design/screens/user_home_screen.dart';
import 'package:afa/design/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:afa/logic/services/user_service.dart';

Future<String?> getUserRole() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final userService = UserService();
  print("gili");
  return await userService.getUserRoleByEmail(user.email!);
}


bool isAuthenticated() {
  return FirebaseAuth.instance.currentUser != null;
}

final GoRouter afaRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
      redirect: (context, state) {
        return _checkRole(context, 'admin', '/login');
      },
    ),
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => FutureBuilder<String?>(
        future: getUserRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const NotFoundScreen();
          }

          final role = snapshot.data;
          print(role);
          if (role == 'Usuario') {
            return const UserHomeScreen();
          } else if (role == 'Conductor') {
            return const DriverHomeScreen();
          } else {
            return const NotFoundScreen();
          }
        },
      ),
      redirect: (context, state) async {
        if (!isAuthenticated()) return '/login';
        final role = await getUserRole();
        if (role == 'Administrador') return '/dashboard';
        return null;
      },
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);

// Helper function for role-based redirection.
Future<String?> _checkRole(BuildContext context, String requiredRole, String fallbackRoute) async {
  final role = await getUserRole();
  if (role != requiredRole) {
    return fallbackRoute;
  }
  return null;
}
