import 'package:afa/logic/providers/loading_provider.dart';
import 'package:afa/logic/router/path/path_url_afa.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SidebarMenu extends StatefulWidget {
  final int selectedIndex; 
  final String userName; 

  const SidebarMenu({
    super.key,
    required this.selectedIndex,// la opcion que esta selañada, si estamos en dasboard sera 1 si estamos en home 0 etc.
    required this.userName,//el usuario que este usando la aplicacion
  });

  @override
  _SidebarMenuState createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  int hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(Icons.home, "Inicio", 0),
                _buildMenuItem(Icons.dashboard, "Panel de control", 1),
                _buildMenuItem(Icons.map, "Mapa", 2),
                _buildMenuItem(Icons.settings, "Configuración", 3),
              ],
            ),
          ),
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    bool isSelected = widget.selectedIndex == index;
    bool isHovered = hoveredIndex == index;
    final loadingProvider =
        Provider.of<LoadingProvider>(context, listen: true);

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = -1),
      child: GestureDetector(
        onTap: () 
        {
          if(index==0){
            loadingProvider.screenChange();
            context.go(PathUrlAfa().pathHome);
          }
          else if (index==1){
            loadingProvider.screenChange();
            context.go(PathUrlAfa().pathDashboard);
          }
          else if (index==2){
            loadingProvider.screenChange();
            context.go(PathUrlAfa().pathMap);
          }
          else if (index==3){
            loadingProvider.screenChange();
            context.go(PathUrlAfa().pathDashboard);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue[700]
                : isHovered
                    ? Colors.blue[100]
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.black54),
              const SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Image.asset(
          "assets/images/logo.png",
          height: 250,
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Text(
          widget.userName, // Nombre de usuario que se le pasa
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
