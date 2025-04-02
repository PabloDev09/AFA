import 'package:afa/design/screens/dashboard_screen.dart';
import 'package:afa/design/screens/driver_home_screen.dart';
import 'package:afa/design/screens/loading_screen.dart';
import 'package:afa/design/screens/login_screen.dart';
import 'package:afa/design/screens/not_found_screen.dart';
import 'package:afa/design/screens/register_screen.dart';
import 'package:afa/design/screens/user_home_screen.dart';
import 'package:afa/design/screens/welcome_screen.dart';
import 'package:afa/logic/providers/loading_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:provider/provider.dart';

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
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'welcome',
      builder: (context, state) => _buildWithLoading(
        context, 
        const WelcomeScreen(),
      )
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => _buildWithLoading(
        context,
        const LoginScreen(),
      )
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => _buildWithLoading(
        context,
        const RegisterScreen(),
      )
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => _buildWithLoading(
        context,
        const DashboardScreen(),
      ),
      redirect: (context, state) async {
        return _checkRole(context, 'admin', '/login');
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => FutureBuilder<String?>(
        future: getUserRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const NotFoundScreen();
          }

          final role = snapshot.data;
          if (role == 'Usuario') {
            return _buildWithLoading(context, const UserHomeScreen());
          } else if (role == 'Conductor') {
            return _buildWithLoading(context, const DriverHomeScreen());
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

/// Muestra la pantalla de carga antes de la transición
Widget _buildWithLoading(BuildContext context, Widget screen) {
  final loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
  
  loadingProvider.screenChange();

      return LoadingScreen(child: screen);
}

/// Helper function para validar el rol de usuario
Future<String?> _checkRole(BuildContext context, String requiredRole, String fallbackRoute) async {
  final role = await getUserRole();
  if (role != requiredRole) {
    return fallbackRoute;
  }
  return null;
}
