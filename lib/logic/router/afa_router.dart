import 'package:afa/design/screens/dashboard_screen.dart';
import 'package:afa/design/screens/home_screen.dart';
import 'package:afa/design/screens/login_screen.dart';
import 'package:afa/design/screens/map_screen.dart';
import 'package:afa/design/screens/not_found_screen.dart';
import 'package:afa/design/screens/register_screen.dart';
import 'package:afa/design/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

bool isAuthenticated() {
  final user = FirebaseAuth.instance.currentUser;
  return user != null; 
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
//      redirect: (context, state) {
//       if (!isAuthenticated()) return '/login';
//       return null;
//     },
    ),
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);
