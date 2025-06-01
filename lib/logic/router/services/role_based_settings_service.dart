import 'package:afa/design/screens/loading_no_child_screen.dart';
import 'package:afa/design/screens/not_found_screen.dart';
import 'package:afa/design/screens/settings_screen.dart';
import 'package:afa/logic/router/afa_router.dart';
import 'package:afa/logic/router/services/delayed_service.dart';
import 'package:flutter/material.dart';

class RoleBasedSettingsService extends StatefulWidget {
  const RoleBasedSettingsService({super.key});

  @override
  State<RoleBasedSettingsService> createState() => _RoleBasedSettingsServiceState();
}

class _RoleBasedSettingsServiceState extends State<RoleBasedSettingsService> {
  Widget? _target;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await getUserRole();
    if (!mounted) return;

    if (role == 'Usuario' || role == 'Conductor' || role == 'Administrador') {
      setState(() {
        _target = const SettingsScreen();
      });
    } else {
      setState(() {
        _target = const NotFoundScreen();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _target == null
        ? const LoadingNoChildScreen()
        : DelayedService(screen: _target!);
  }
}

