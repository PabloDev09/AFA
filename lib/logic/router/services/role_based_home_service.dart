import 'package:afa/design/screens/dashboard_screen.dart';
import 'package:afa/design/screens/driver_home_screen.dart';
import 'package:afa/design/screens/loading_no_child_screen.dart';
import 'package:afa/design/screens/not_found_screen.dart';
import 'package:afa/design/screens/user_home_screen.dart';
import 'package:afa/logic/router/afa_router.dart';
import 'package:afa/logic/router/services/delayed_service.dart';
import 'package:flutter/material.dart';

class RoleBasedHomeService extends StatefulWidget {
  const RoleBasedHomeService({super.key});

  @override
  State<RoleBasedHomeService> createState() => _RoleBasedHomeServiceState();
}

class _RoleBasedHomeServiceState extends State<RoleBasedHomeService> {
  Widget? _target;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await getUserRole();
    if (!mounted) return;

    Widget targetScreen;
    if (role == 'Usuario') {
      targetScreen = const UserHomeScreen();
    } else if (role == 'Conductor') {
      targetScreen = const DriverHomeScreen();
    } else if (role == 'Administrador') {
      targetScreen = const DashboardScreen();
    } else {
      targetScreen = const NotFoundScreen();
    }

    setState(() {
      _target = targetScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _target == null
        ? const LoadingNoChildScreen()
        : DelayedService(screen: _target!);
  }
}

