import 'package:afa/firebase_options.dart';
import 'package:afa/logic/providers/active_user_provider.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/logic/providers/bus_provider.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:afa/logic/providers/pending_user_provider.dart';
import 'package:afa/logic/providers/register_provider.dart';
import 'package:afa/logic/providers/theme_provider.dart';
import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:afa/design/themes/afa_theme.dart';
import 'package:afa/logic/router/afa_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
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
        // 1. Proveedores independientes
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RegisterProvider()),
        ChangeNotifierProvider(create: (_) => PendingUserProvider()..loadPendingUsers()),
        ChangeNotifierProvider(create: (_) => ActiveUserProvider()..loadActiveUsers()),
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // 2. DriverRouteProvider depende de NotificationProvider
        ChangeNotifierProxyProvider<NotificationProvider, DriverRouteProvider>(
          create: (ctx) => DriverRouteProvider(ctx.read<NotificationProvider>()),
          update: (ctx, notif, prev) => prev!
            ..updateNotificationProvider(notif)
            ..notifyListeners(),
        ),

        // 3. UserRouteProvider depende de NotificationProvider
        ChangeNotifierProxyProvider<NotificationProvider, UserRouteProvider>(
          create: (ctx) => UserRouteProvider(ctx.read<NotificationProvider>()),
          update: (ctx, notif, prev) => prev!
            ..updateNotificationProvider(notif)
            ..notifyListeners(),
        ),

        // 4. AuthUserProvider depende de:
        //    - NotificationProvider
        //    - DriverRouteProvider
        //    - UserRouteProvider
        ChangeNotifierProxyProvider3<
          NotificationProvider,
          DriverRouteProvider,
          UserRouteProvider,
          AuthUserProvider
        >(
          create: (_) => AuthUserProvider(
            // Temporal hasta el primer update, no se usa antes de update
            NotificationProvider(),
            DriverRouteProvider(NotificationProvider()),
            UserRouteProvider(NotificationProvider()),
          )..loadUser(),
          update: (ctx, notif, drvRoute, usrRoute, auth) {
            // Reemplazamos las referencias de dependencia y recargamos usuario
            auth!
              ..updateDependencies(
                notificationProvider: notif,
                driverRouteProvider: drvRoute,
                userRouteProvider: usrRoute,
              )
              ..loadUser()
              ..notifyListeners();
            return auth;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (ctx, themeProv, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AfaTheme.theme(themeProv.isDarkMode, 1),
            routerConfig: afaRouter,
          );
        },
      ),
    );
  }
}
