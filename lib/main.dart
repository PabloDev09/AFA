import 'package:afa/logic/providers/bus_provider.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:afa/logic/providers/loading_provider.dart';
import 'package:afa/logic/providers/routes_provider.dart';
import 'package:afa/logic/providers/theme_provider.dart';
import 'package:afa/logic/providers/user_active_provider.dart';
import 'package:afa/logic/providers/user_pending_provider.dart';
import 'package:afa/design/themes/afa_theme.dart';
import 'package:afa/design/screens/loading_screen.dart';
import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:afa/logic/router/afa_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:afa/logic/providers/user_register_provider.dart';


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
        ChangeNotifierProvider(create: (_) => UserRegisterProvider()),
        ChangeNotifierProvider(create: (_) => UserPendingProvider()..chargeUsers()),
        ChangeNotifierProvider(create: (_) => UserActiveProvider()..chargeUsers()),
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RoutesProvider()),
        ChangeNotifierProvider(create: (_) => DriverRouteProvider()),
        ChangeNotifierProvider(create: (_) => UserRouteProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            builder: (context, child) {
              return LoadingScreen(child: child!);
            },
            theme: AfaTheme.theme(
              themeProvider.isDarkMode, 
              1
            ),
            debugShowCheckedModeBanner: false,
            routerConfig: afaRouter,
          );
        },
      ),
    );
  }
}
