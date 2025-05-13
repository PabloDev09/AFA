import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:afa/logic/router/path/path_url_afa.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SidebarMenu extends StatefulWidget {
  final int selectedIndex; 

  const SidebarMenu({
    super.key,
    required this.selectedIndex,
  });

  @override
  _SidebarMenuState createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  int hoveredIndex = -1;

  Widget _buildMenuItem(IconData icon, String title, int index, String route) {
    bool isSelected = widget.selectedIndex == index;
    bool isHovered = hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50), // reduced height
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: isSelected ? Colors.white : Colors.black87, backgroundColor: isSelected
                ? Colors.blue[700]
                : isHovered
                    ? Colors.blue[100]
                    : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // smaller padding
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // slightly smaller radius
            elevation: 0,
          ),
          onPressed: () {
            context.go(route);
          },
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.black54, size: 24), // smaller icon
              const SizedBox(width: 16), // smaller spacing
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16, // smaller font
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0), // smaller padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, color: Colors.black54, size: 30), // smaller icon
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${Provider.of<AuthUserProvider>(context, listen: false).userFireStore!.name} ${Provider.of<AuthUserProvider>(context, listen: false).userFireStore!.surnames}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), // smaller font
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // smaller spacing
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => hoveredIndex = 100),
            onExit: (_) => setState(() => hoveredIndex = -1),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50), // smaller button height
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: hoveredIndex == 100 ? Colors.red[700] : Colors.red[600],
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // smaller padding
                  alignment: Alignment.center,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: hoveredIndex == 100 ? 4 : 0,
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Provider.of<AuthUserProvider>(context, listen: false).logout();
                  Provider.of<NotificationProvider>(context, listen: false).clearNotifications();
                  Provider.of<DriverRouteProvider>(context, listen: false).clearRoutes();
                  Provider.of<UserRouteProvider>(context, listen: false).clearRoutes();
                  context.go(PathUrlAfa().pathLogin);
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.white, size: 24), // smaller icon
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Cerrar sesión',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), // smaller font
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240, // smaller width
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // smaller padding
            child: Center(
              child: Image.asset("assets/images/logo.png", height: 160, fit: BoxFit.contain), // smaller logo
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8), // smaller padding
              child: Column(
                children: [
                  _buildMenuItem(Icons.home, "Inicio", 0, PathUrlAfa().pathHome),
                  const SizedBox(height: 10),
                  _buildMenuItem(Icons.dashboard, "Panel de control", 1, PathUrlAfa().pathDashboard),
                  const SizedBox(height: 10),
                  _buildMenuItem(Icons.map, "Mapa", 2, PathUrlAfa().pathMap),
                  const SizedBox(height: 10),
                  _buildMenuItem(Icons.settings, "Configuración", 3, PathUrlAfa().pathSettings),
                ],
              ),
            ),
          ),
          _buildUserProfile(),
        ],
      ),
    );
  }
}
