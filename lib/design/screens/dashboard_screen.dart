import 'package:afa/design/components/pending_user_component.dart';
import 'package:afa/design/components/active_user_component.dart';
import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/providers/active_user_provider.dart';
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
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final RouteService _routeService = RouteService();
  
  Future<void> _showAssignRouteDialog() async {
    final activeProvider = Provider.of<ActiveUserProvider>(context, listen: false);
    User? selectedUser;
    List<int> rutas = await _routeService.getAllRouteNumbers();
    int selectedRoute = 0;
    int pickOrder = 1;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Asignar Ruta'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Selector de usuario
                DropdownButton<User>(
                  isExpanded: true,
                  hint: const Text('Selecciona un usuario'),
                  value: selectedUser,
                  items: activeProvider.activeUsers
                  .where((u) => u.rol.trim() == 'Usuario')
                  .map((u) {
                    return DropdownMenuItem(
                      value: u,
                      child: Text('${u.name} ${u.surnames}'),
                    );
                  }).toList(),
                  onChanged: (u) => setState(() => selectedUser = u),
                ),
                const SizedBox(height: 12),
                // 2. Selector de numRoute
                Row(
                  children: [
                    const Text('Ruta:'),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: selectedRoute,
                      items: rutas
                        .map((r) => DropdownMenuItem(value: r, child: Text('$r')))
                        .toList(),
                      onChanged: (r) => setState(() => selectedRoute = r!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 3. Campo numérico para pickOrder
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (selectedUser != null) {
                activeProvider.assignRoute(selectedUser!, selectedRoute, pickOrder);
              }
              Navigator.pop(context);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

    /// Diálogo para crear una nueva ruta en Firestore
  void _showCreateRouteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear nueva ruta'),
        content: const Text('¿Estás seguro de crear una nueva ruta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              // Obtener último numRoute y añadir +1
              int last = await _routeService.getMaxRouteNumber();
              await _routeService.createRouteNumber(last + 1);
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nueva ruta creada exitosamente')),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  /// Diálogo para borrar una ruta existente
  void _showDeleteRouteDialog() async {
    setState(() => _isLoading = true);
    List<int> rutas = await _routeService.getAllRouteNumbers();
    setState(() => _isLoading = false);

    int? selectedRoute = 0;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar ruta'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButton<int>(
              isExpanded: true,
              hint: const Text('Selecciona una ruta'),
              value: selectedRoute,
              items: rutas
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text('Ruta $r'),
                      ))
                  .toList(),
              onChanged: (r) => setState(() => selectedRoute = r),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: 
              () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                await _routeService.deleteRouteNumber(selectedRoute!);
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ruta $selectedRoute eliminada')),
                );
              },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  Future<void> _uploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isLoading = true);

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
          const SnackBar(content: Text("Documento subido con éxito")),
        );
      }
    } catch (e) {
      print("❌ Error al subir documento: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al subir el documento")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor:
            _isMenuOpen ? const Color.fromARGB(30, 0, 0, 0) : Colors.transparent,
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
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      Icon(
                        Icons.dashboard,
                        color: _isMenuOpen ? Colors.blue[700] : Colors.white,
                        size: 30,
                      ),
                      const SizedBox(width: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final textSize =
                              constraints.maxWidth > 200 ? 24.0 : 20.0;
                          return Text(
                            'Panel de administración',
                            style: TextStyle(
                              color:
                                  _isMenuOpen ? Colors.blue[700] : Colors.white,
                              fontSize: textSize,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          Consumer<PendingUserProvider>(
                            builder: (context, userPendingProvider, child) {
                              final count = userPendingProvider.pendingUsers.length;
                              return count > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
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
                          const SizedBox(width: 6),
                          const Icon(Icons.person_add_alt_rounded,
                              color: Colors.white),
                          const SizedBox(width: 6),
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
                          const SizedBox(width: 6),
                          const Icon(Icons.person, color: Colors.white),
                          const SizedBox(width: 6),
                          Consumer<ActiveUserProvider>(
                            builder: (context, activeProvider, child) {
                              final activeCount =
                                  activeProvider.activeUsers.length;
                              return activeCount > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
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
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if(_showActiveUsers)
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              // Se define el contenido del botón según el ancho de la pantalla.
              final Widget content = screenWidth >= 800
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Crear Ruta',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Icon(Icons.add, color: Colors.white);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: _showCreateRouteDialog,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth >= 800 ? 16 : 12,
                      vertical: 10,
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
                  ),
                ),
              );
            },
          ),
          if(_showActiveUsers)
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              // Se define el contenido del botón según el ancho de la pantalla.
              final Widget content = screenWidth >= 800
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.route, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Asignar Ruta',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Icon(Icons.route, color: Colors.white);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: _showAssignRouteDialog,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth >= 800 ? 16 : 12,
                      vertical: 10,
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
                  ),
                ),
              );
            },
          ),
          if(_showActiveUsers)
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              // Se define el contenido del botón según el ancho de la pantalla.
              final Widget content = screenWidth >= 800
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Borrar Ruta',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Icon(Icons.delete, color: Colors.white);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: _showDeleteRouteDialog,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth >= 800 ? 16 : 12,
                      vertical: 10,
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
                  ),
                ),
              );
            },
          ),
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              // Se define el contenido del botón según el ancho de la pantalla.
              final Widget content = screenWidth >= 800
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_file, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Subir Documento',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Icon(Icons.upload_file, color: Colors.white);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: _uploadDocument,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth >= 800 ? 16 : 12,
                      vertical: 10,
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
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFF063970),
                  theme.brightness == Brightness.dark
                      ? const Color(0xFF121212)
                      : const Color(0xFF66B3FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
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
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          if (_isMenuOpen)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SidebarMenu(
                selectedIndex: 1,
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                '© 2025 AFA Andújar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
