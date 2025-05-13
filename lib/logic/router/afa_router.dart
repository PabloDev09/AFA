import 'package:afa/design/screens/dashboard_screen.dart';
import 'package:afa/design/screens/driver_home_screen.dart';
import 'package:afa/design/screens/loading_no_child_screen.dart';
import 'package:afa/design/screens/login_screen.dart';
import 'package:afa/design/screens/not_found_screen.dart';
import 'package:afa/design/screens/register_screen.dart';
import 'package:afa/design/screens/settings_screen.dart';
import 'package:afa/design/screens/user_home_screen.dart';
import 'package:afa/design/screens/welcome_screen.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


Future<String?> getUserRole() async 
{
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final userService = UserService();
  return await userService.getUserRoleByEmail(user.email!);
}

bool isAuthenticated() 
{
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


Future<String?> _checkRole(
    BuildContext context, String requiredRole, String fallbackRoute) async {
  final role = await getUserRole();
  if (role != requiredRole) {
    return fallbackRoute;
  }
  return null;
}

final GoRouter afaRouter = GoRouter(
  initialLocation: '/',
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
      /// Si el usuario ya está autenticado, redirige a /home
      redirect: (context, state) {
        if (isAuthenticated()) return '/home';
        return null;
      },
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
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => _buildWithLoading(
        context,
        const DashboardScreen(),
        delay: const Duration(seconds: 2),
      ),
      redirect: (context, state) async {
        return _checkRole(context, 'Administrador', '/login');
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => FutureBuilder<String?>(
        future: getUserRole(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            // Mientras no se obtenga el rol se muestra el loader indefinidamente.
            return const LoadingNoChildScreen();
          }
          final role = snapshot.data;
          Widget targetScreen;
          if (role == 'Usuario') {
            targetScreen = const UserHomeScreen();
          } else if (role == 'Conductor') {
            targetScreen = const DriverHomeScreen();
          } else {
            // Si el rol no coincide con los esperados, se muestra loader indefinido.
            targetScreen = const LoadingNoChildScreen();
          }

          return _buildWithLoading(
            context,
            targetScreen,
            delay: const Duration(seconds: 3),
          );
        },
      ),
      redirect: (context, state) async {
        if (!isAuthenticated()) return '/login';
        final role = await getUserRole();
        if (role == 'Administrador') return '/dashboard';
        return null;
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => FutureBuilder<String?>(
        future: getUserRole(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            // Mientras no se obtenga el rol se muestra el loader indefinidamente.
            return const LoadingNoChildScreen();
          }
          final role = snapshot.data;
          Widget targetScreen;
          if (role == 'Usuario' || role == 'Conductor') {
            targetScreen = const SettingsScreen();
          } 
          else {
            // Si el rol no coincide con los esperados, se muestra loader indefinido.
            targetScreen = const LoadingNoChildScreen();
          }

          return _buildWithLoading(
            context,
            targetScreen,
            delay: const Duration(seconds: 3),
          );
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
  errorBuilder: (context, state) => FutureBuilder(
  future: Future.delayed(const Duration(seconds: 3)),
  builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const LoadingNoChildScreen(); 
    }
    return const NotFoundScreen();
  },
)

);
