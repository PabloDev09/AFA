import 'package:afa/design/components/pending_user_component.dart';
import 'package:afa/design/components/active_user_component.dart';
import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/providers/active_user_provider.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/logic/providers/pending_user_provider.dart';
import 'package:afa/design/components/side_bar_menu.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _showActiveUsers = false;
  bool _isMenuOpen = false;
  late ScrollController _scrollController;
  bool _scrolledDown = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final RouteService _routeService = RouteService();
  
    @override
  void initState() {
    super.initState();

      _scrollController = ScrollController();
      _scrollController.addListener(() {
    if (_scrollController.offset > 20 && !_scrolledDown) {
      setState(() {
        _scrolledDown = true;
      });
    } else if (_scrollController.offset <= 20 && _scrolledDown) {
      setState(() {
        _scrolledDown = false;
      });
    }
  });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();


  WidgetsBinding.instance.addPostFrameCallback((_) async 
  {
    await Provider.of<AuthUserProvider>(context, listen: false).loadUser();
  });
  }

@override
void dispose() {
  _scrollController.dispose();
  _animationController.dispose();
  super.dispose();
}
  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }


Future<void> _showAssignRouteDialog() async {
  final activeProvider = Provider.of<ActiveUserProvider>(context, listen: false);
  User? selectedUser;
  List<int> rutas = await _routeService.getAllRouteNumbers();

  // Agregar opción especial 0 para "Desasignar"
  rutas.insert(0, 0);

  int selectedRoute = rutas.first; // Ahora 0 será el valor inicial
  int pickOrder = 1;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF063970), Color(0xFF2196F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Asignar Ruta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButton<User>(
                isExpanded: true,
                hint: const Text('Selecciona un usuario'),
                value: selectedUser,
                items: activeProvider.activeUsers
                    .where((u) => u.rol.trim() == 'Usuario')
                    .map((u) => DropdownMenuItem(
                          value: u,
                          child: Text('${u.name} ${u.surnames}'),
                        ))
                    .toList(),
                onChanged: (u) => setState(() => selectedUser = u),
              ),
              const SizedBox(height: 12),

              // 👇 Mostrar información del usuario seleccionado
              if (selectedUser != null)
                Card(
                  color: Colors.blue[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("👤 Usuario: ${selectedUser!.name} ${selectedUser!.surnames}",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text("🛣 Ruta actual: ${selectedUser?.numRoute ?? 0}"),
                        const SizedBox(height: 6),
                        Text("🔢 Orden: ${selectedUser?.numPick ?? 'Sin determinar'}"),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Ruta:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: selectedRoute,
                    items: rutas
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r == 0 ? 'Desasignar' : 'Ruta $r'),
                            ))
                        .toList(),
                    onChanged: (r) {
                      setState(() {
                        selectedRoute = r!;
                        // Si desasigna, resetear pickOrder a null
                        if (selectedRoute == 0) {
                          pickOrder = 1;
                        }
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),
              if (selectedRoute != 0) // 👈 Mostrar solo si no es "Desasignar"
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Orden de recogida',
                    hintText: '1, 2, 3...',
                  ),
                  onChanged: (txt) {
                    final v = int.tryParse(txt);
                    if (v != null && v > 0) setState(() => pickOrder = v);
                  },
                ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (selectedUser != null) {
                activeProvider.assignRoute(selectedUser!, selectedRoute, pickOrder);
            }
            Navigator.pop(context);
          },
          child: const Text("Confirmar"),
        ),
      ],
    ),
  );
}

void _showCreateRouteDialog() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF063970), Color(0xFF2196F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Crear nueva ruta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      content: const Text('¿Estás seguro de crear una nueva ruta?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.pop(context);
            int last = await _routeService.getMaxRouteNumber();
            await _routeService.createRouteNumber(last + 1);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nueva ruta creada exitosamente'), backgroundColor: Colors.green),
            );
          },
          child: const Text('Crear'),
        ),
      ],
    ),
  );
}

void _showDeleteRouteDialog() async {
  List<int> rutas = await _routeService.getAllRouteNumbers();

  int? selectedRoute = rutas.isNotEmpty ? rutas.first : null;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF063970), Color(0xFF2196F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Eliminar ruta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      content: StatefulBuilder(
        builder: (context, setState) {
          return DropdownButton<int>(
            isExpanded: true,
            hint: const Text('Selecciona una ruta'),
            value: selectedRoute,
            items: rutas.map((r) {
              return DropdownMenuItem(
                value: r,
                child: Text('Ruta $r'),
              );
            }).toList(),
            onChanged: (r) => setState(() => selectedRoute = r),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: selectedRoute != null
              ? () async {
                  Navigator.pop(context);
                  await _routeService.deleteRouteNumber(selectedRoute!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ruta $selectedRoute eliminada'), backgroundColor: Colors.green),
                  );
                }
              : null,
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
}

  Future<void> _uploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {

        var file = result.files.first;
        String fileName = file.name;

        Reference storageRef =
        FirebaseStorage.instance.ref().child('documents/$fileName');
        UploadTask uploadTask = storageRef.putData(file.bytes!);

        TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('documents').add({
          'title': fileName,
          'fileUrl': downloadUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Documento subido con éxito"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("❌ Error al subir documento: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al subir el documento"), backgroundColor: Colors.red),
      );
    } 
  }

Widget buildActionButton({
  required BuildContext context,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final bool showText = screenWidth >= 1000;

  // Tamaño dinámico del icono
  final double iconSize = showText ? 24 : 18;

  final Widget content = showText
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: iconSize),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        )
      : Icon(icon, color: Colors.white, size: iconSize);

  final button = Container(
    padding: EdgeInsets.symmetric(
      horizontal: showText ? 16 : 8,  // menos padding si no muestra texto
      vertical: showText ? 10 : 6,
    ),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Colors.blueAccent, Colors.lightBlue],
      ),
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          offset: Offset(0, 2),
          blurRadius: 6,
        )
      ],
    ),
    child: content,
  );

  Widget scaledButton = button;

  // Si no muestra texto, envolver en FittedBox para reducir tamaño completo
  if (!showText) {
    scaledButton = FittedBox(
      fit: BoxFit.scaleDown,
      child: button,
    );
  }

  return Padding(
    padding: const EdgeInsets.only(right: 8.0),
    child: InkWell(
      onTap: onTap,
      child: showText ? button : Tooltip(message: label, child: scaledButton),
    ),
  );
}


    @override
    Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
      backgroundColor: _isMenuOpen
          ? const Color.fromARGB(30, 0, 0, 0)
          : _scrolledDown
              ? Colors.black.withOpacity(0.5)  // negro transparente al hacer scroll
              : Colors.transparent,

          elevation: 0,
          title: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isMenuOpen ? Icons.close : Icons.menu,
                  color: _isMenuOpen ? Colors.blue[700] : Colors.white,
                ),
                onPressed: _toggleMenu,
              ),

              // Aquí ponemos el bloque que quieres al lado del menú, sin Expanded
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      Consumer<PendingUserProvider>(
                        builder: (context, userPendingProvider, child) {
                          final count = userPendingProvider.pendingUsers.length;
                          return count > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : const SizedBox();
                        },
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.person_add_alt_rounded, color: Colors.white),
                      const SizedBox(width: 3),
                      Switch(
                        value: _showActiveUsers,
                        onChanged: (bool value) {
                          setState(() {
                            _showActiveUsers = value;
                          });
                        },
                        activeColor: Colors.white,
                        activeTrackColor: Colors.lightBlue,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey,
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.person, color: Colors.white),
                      const SizedBox(width: 3),
                      Consumer<ActiveUserProvider>(
                        builder: (context, activeProvider, child) {
                          final activeCount = activeProvider.activeUsers.length;
                          return activeCount > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$activeCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                )
                              : const SizedBox();
                        },
                      ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (_showActiveUsers)
              buildActionButton(
                context: context,
                icon: Icons.add,
                label: 'Crear Ruta',
                onTap: _showCreateRouteDialog,
              ),
            if (_showActiveUsers)
              buildActionButton(
                context: context,
                icon: Icons.route,
                label: 'Asignar Ruta',
                onTap: _showAssignRouteDialog,
              ),
            if (_showActiveUsers)
              buildActionButton(
                context: context,
                icon: Icons.delete,
                label: 'Eliminar Ruta',
                onTap: _showDeleteRouteDialog,
              ),
            buildActionButton(
              context: context,
              icon: Icons.upload_file,
              label: 'Subir Documento',
              onTap: _uploadDocument,
            ),
          ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFF063970),
                  theme.brightness == Brightness.dark ? const Color(0xFF121212) : const Color(0xFF66B3FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _showActiveUsers
                          ? const ActiveUserComponent()
                          : const PendingUserComponent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
          if (_isMenuOpen)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SidebarMenu(selectedIndex: 1),
            ),
        ],
      ),
    );
  }
}
