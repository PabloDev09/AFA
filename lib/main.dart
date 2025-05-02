import 'package:afa/logic/providers/active_user_provider.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/logic/providers/bus_provider.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:afa/logic/providers/routes_provider.dart';
import 'package:afa/logic/providers/theme_provider.dart';
import 'package:afa/logic/providers/pending_user_provider.dart';
import 'package:afa/design/themes/afa_theme.dart';
import 'package:afa/logic/providers/user_register_provider.dart';
import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:afa/logic/router/afa_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setUrlStrategy(PathUrlStrategy());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        /// El proveedor de notificaciones:
        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        /// Autenticación:
        ChangeNotifierProvider(create: (_) => AuthUserProvider()..loadUser()),

        /// Otros:
        ChangeNotifierProvider(create: (_) => UserRegisterProvider()),
        ChangeNotifierProvider(create: (_) => PendingUserProvider()..loadPendingUsers()),
        ChangeNotifierProvider(create: (_) => ActiveUserProvider()..loadActiveUsers()),
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RoutesProvider()),

        /// Proxy para DriverRouteProvider:
        ChangeNotifierProxyProvider<NotificationProvider, DriverRouteProvider>(
          create: (context) => DriverRouteProvider(
            context.read<NotificationProvider>(),
          ),
          update: (context, notificationProvider, previous) {
            previous!
              ..updateNotificationProvider(notificationProvider)
              ..notifyListeners();
            return previous;
          },
        ),

        /// Proxy para UserRouteProvider:
        ChangeNotifierProxyProvider<NotificationProvider, UserRouteProvider>(
          create: (context) => UserRouteProvider(
            context.read<NotificationProvider>(),
          ),
          update: (context, notificationProvider, previous) {
            previous!
              ..updateNotificationProvider(notificationProvider)
              ..notifyListeners();
            return previous;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            theme: AfaTheme.theme(
              themeProvider.isDarkMode, 
              1,
            ),
            debugShowCheckedModeBanner: false,
            routerConfig: afaRouter,
          );
        },
      ),
    );
  }
}
