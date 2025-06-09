import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/logic/router/path/path_url_afa.dart';
import 'package:afa/utils.dart';
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
        constraints: const BoxConstraints(minHeight: 50),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            backgroundColor: isSelected
                ? Colors.blue[700]
                : isHovered
                    ? Colors.blue[100]
                    : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          onPressed: () {
            // Navegamos y cerramos drawer
            Navigator.of(context).pop();
            Future.microtask(() {
              if (mounted) {
                context.go(route);
              }
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.black54, size: 24),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
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
      const TextStyle nameStyle = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
         Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                radius: 16,
                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                fit: FlexFit.loose,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${Provider.of<AuthUserProvider>(context, listen: false).userFireStore!.name} '
                        '${Utils().getSurnameInitials(Provider.of<AuthUserProvider>(context, listen: false).userFireStore!.surnames)}',
                        style: nameStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            size: nameStyle.fontSize != null ? nameStyle.fontSize! * 0.7 : 12,
                            color: Colors.green.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${Provider.of<AuthUserProvider>(context, listen: false).userFireStore!.rol} verificado',
                            style: TextStyle(
                              fontSize: nameStyle.fontSize != null ? nameStyle.fontSize! * 0.7 : 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

          const SizedBox(height: 16),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => hoveredIndex = 100),
            onExit: (_) => setState(() => hoveredIndex = -1),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 50),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: hoveredIndex == 100 ? Colors.red[700] : Colors.red[600],
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  alignment: Alignment.center,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: hoveredIndex == 100 ? 4 : 0,
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Provider.of<AuthUserProvider>(context, listen: false).logout();
                  
                  // Primero cerramos el drawer
                  Navigator.of(context).pop();
    
                  // Después navegamos en la siguiente frame para evitar usar contexto desactivado
                  Future.microtask(() {
                    if (mounted) {
                      context.go(PathUrlAfa().pathLogin);
                    }
                  });
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.white, size: 24),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Cerrar sesión',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          // Botón cerrar drawer
          Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(top: 12, left: 12),
            child: IconButton(
              icon: const Icon(Icons.close),
              iconSize: 28,
              color: Colors.blue[800],
              tooltip: 'Cerrar',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),

          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Image.asset("assets/images/logo.png", height: 160, fit: BoxFit.contain),
            ),
          ),

          const SizedBox(height: 16),

          // Menú
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  _buildMenuItem(Icons.home, "Inicio", 0, PathUrlAfa().pathHome),
                  const SizedBox(height: 10),
                  _buildMenuItem(Icons.settings, "Configuración", 1, PathUrlAfa().pathSettings),
                ],
              ),
            ),
          ),

          // Perfil y botón cerrar sesión
          _buildUserProfile(),
        ],
      ),
    );
  }
}
