import 'package:afa/design/screens/dashboard_screen.dart';
import 'package:afa/design/screens/driver_home_screen.dart';
import 'package:afa/design/screens/login_screen.dart';
import 'package:afa/design/screens/map_screen.dart';
import 'package:afa/design/screens/not_found_screen.dart';
import 'package:afa/design/screens/register_screen.dart';
import 'package:afa/design/screens/user_home_screen.dart';
import 'package:afa/design/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:afa/logic/services/user_service.dart';

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
        // Solo permite el acceso a usuarios autenticados y con rol admin
        if (!isAuthenticated() || getUserRole() != 'admin') return '/login';
        return null;
      },
    ),
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (context, state) => const MapScreen(),
    ),
    // Ruta única /home que redirige según el rol del usuario
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) {
        final role = getUserRole();
        // Dependiendo del rol, regresa la pantalla correspondiente
        if (role == 'Usuario') {
          return const UserHomeScreen();
        } else if (role == 'Conductor') {
          return const DriverHomeScreen();
        } else {
          // Si el rol no corresponde a ninguno, se muestra una pantalla de error o NotFound
          return const NotFoundScreen();
        }
      },
      redirect: (context, state) {
        // Si no está autenticado o es admin (que no debe usar /home) se redirige.
        if (!isAuthenticated()) return '/login';
        if (getUserRole() == 'Administrador') return '/dashboard';
        return null;
      },
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);
