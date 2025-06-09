import 'package:afa/design/components/notice_board_component.dart';
import 'package:afa/design/components/pending_user_component.dart';
import 'package:afa/design/components/active_user_component.dart';
import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/providers/active_user_provider.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/logic/providers/pending_user_provider.dart';
import 'package:afa/design/components/side_bar_menu.dart';
import 'package:afa/logic/services/number_route_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _showActiveUsers = false;
  bool _scrolledDown = false;

  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final NumberRouteService _numberRouteService = NumberRouteService();

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AuthUserProvider>(context, listen: false).loadUser();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

    void _openNoticeBoard() 
  {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return NoticeBoardComponent(scrollController: scrollController, rol: Provider.of<AuthUserProvider>(context, listen: false).userFireStore!.rol);
        },
      ),
    );
  }

  Future<void> _showAssignRouteDialog() async {
    final activeProvider =
        Provider.of<ActiveUserProvider>(context, listen: false);
    User? selectedUser;
    List<int> rutas = await _numberRouteService.getDistinctRouteNumbers();

  // Añadir opción para desasignar al principio
  rutas.insert(0, 0);
  int selectedRoute = rutas.first;
  int pickOrder = 1;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),

      // TITULAR
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
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),

      // CONTENIDO
      content: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // DROPDOWN USUARIO
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<User>(
                      isExpanded: true,
                      hint: const Text('Selecciona un usuario'),
                      value: selectedUser,
                      items: activeProvider.activeUsers
                          .where((u) => u.rol.trim() == 'Usuario')
                          .map((u) => DropdownMenuItem(
                                value: u,
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_circle_outlined, color: Colors.blueAccent),
                                    const SizedBox(width: 8),
                                    Text('${u.name} ${u.surnames}'),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (u) => setState(() => selectedUser = u),
                    ),
                  ),
                ),

                // INFO USUARIO
                if (selectedUser != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_circle_outlined, size: 20, color: Colors.blueAccent),
                            const SizedBox(width: 6),
                            Text(
                              '${selectedUser?.name} ${selectedUser?.surnames}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.alt_route, color: Colors.indigo.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Ruta actual: ${selectedUser?.numRoute}',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.indigo.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.teal.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Parada actual: ${selectedUser?.numPick}',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                if (selectedUser != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      hint: const Text('Selecciona una ruta'),
                      value: selectedRoute,
                      items: rutas
                          .map((r) => DropdownMenuItem(
                                value: r,
                                child: Row(
                                  children: [
                                    Icon(r == 0 ? Icons.clear : Icons.alt_route,
                                        color: r == 0 ? Colors.red : Colors.indigo),
                                    const SizedBox(width: 8),
                                    Text(r == 0 ? 'Desasignar ruta' : 'Ruta $r'),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (r) {
                        setState(() {
                          selectedRoute = r!;
                          if (selectedRoute == 0) pickOrder = 1;
                        });
                      },
                    ),
                  ),
                ),

                // CAMPO PARADA
                if (selectedRoute != 0)
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.location_on, color: Color(0xFF00796B)),
                      labelText: 'Parada',
                      hintText: '1, 2, 3...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (txt) {
                      final v = int.tryParse(txt);
                      if (v != null && v > 0) pickOrder = v;
                    },
                  ),
              ],
            ),
          );
        },
      ),

      // ACCIONES
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF063970), Color(0xFF2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed:() {
                    if(selectedUser == null || pickOrder == 0)
                    {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debes seleccionar una ruta y parada válida'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                     
                    Navigator.pop(context);
                    activeProvider.assignRoute(selectedUser!, selectedRoute, pickOrder);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.white.withOpacity(0.2);
                        }
                        return null;
                      }),
                    ),
                  child: const Text(
                    'Asignar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
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
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF66BB6A),],          
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[800],
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A),],          
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    int last = await _numberRouteService.getMaxRouteNumber();
                    await _numberRouteService.createRouteNumber(last + 1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nueva ruta creada con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.white.withOpacity(0.2);
                        }
                        return null;
                      }),
                    ),
                  child: const Text('Crear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

void _showDeleteRouteDialog() async {
  List<int> rutas = await _numberRouteService.getDistinctRouteNumbers();
  int? selectedRoute = rutas.isNotEmpty ? rutas.first : null;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
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
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selecciona una ruta a eliminar:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: selectedRoute,
                    hint: const Text('Selecciona una ruta'),
                    items: rutas.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text('Ruta $r'),
                      );
                    }).toList(),
                    onChanged: (r) => setState(() => selectedRoute = r),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[800],
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.red, Color(0xFFB71C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: selectedRoute != null
                      ? () async {
                          Navigator.pop(context);
                          await _numberRouteService.deleteRouteNumber(selectedRoute!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ruta $selectedRoute eliminada con éxito'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.white.withOpacity(0.2);
                        }
                        return null;
                      }),
                    ),
                  child: const Text('Eliminar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  
Widget buildActionButton({
  required BuildContext context,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final bool showText = screenWidth >= 1000;
  final double iconSize = showText ? 24 : 18;

  // ✅ Gradiente condicional según el texto
  final Gradient buttonGradient;

        if(label.toLowerCase() == 'crear ruta')
        {
          buttonGradient =
           const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF66BB6A),],                  
            );
        }
        else if(label.toLowerCase() == 'eliminar ruta')
        {
          buttonGradient =
          const LinearGradient(
          colors: [Colors.green, Colors.lightGreen],
        );
        }
        else
        {
          buttonGradient =
          const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
        );
        }

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
      horizontal: showText ? 16 : 8,
      vertical: showText ? 10 : 6,
    ),
    decoration: BoxDecoration(
      gradient: buttonGradient,
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    ),
    child: content,
  );

    Widget scaledButton = button;

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
      child: showText
          ? button
          : Tooltip(
              message: label,
              child: scaledButton,
            ),
    ),
  );
}



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const Drawer( child: SidebarMenu(selectedIndex: 0,),),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          tooltip: 'Menú', 
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      backgroundColor: _scrolledDown
              ? Colors.black.withOpacity(0.4)  // negro transparente al hacer scroll
              : Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
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
              const Spacer(),
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
                icon: Icons.alt_route,
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
            IconButton(
              icon: const Icon(Icons.feed, color: Colors.white),
              tooltip: 'Tablón',
              onPressed: _openNoticeBoard,
              ),
          ],
      ),
      body: 
      Stack(
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
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 5),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 50),
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
          ),

        ],
      ),
    );
  }
  

}
