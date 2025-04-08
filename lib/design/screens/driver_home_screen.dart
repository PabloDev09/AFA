import 'dart:async';
import 'package:afa/design/components/chat_component.dart';
import 'package:afa/design/components/route_user_component.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart'; 

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final DateTime _focusedDay = DateTime.now();
  late Timer _timer;
  bool isNotDriver = false; // Cambiar este valor según si el usuario es conductor o no

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();

    _verificarRutaPendiente();
  }

  Future<void> _verificarRutaPendiente() async {
    final routeProvider = Provider.of<DriverRouteProvider>(context, listen: false);
    bool hayRutaPendiente = await routeProvider.canResumeRoute();

    if (hayRutaPendiente) {
      await routeProvider.resumeRoute();
      setState(() {}); // Actualiza la UI para reflejar la ruta activa
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _stopTimer() {
    _timer.cancel();
  }

  Future<void> _confirmarAccion(bool iniciar, DriverRouteProvider routeProvider) async {
    String accion = iniciar ? "Iniciar" : "Detener";
    Color color = iniciar ? Colors.blue : Colors.red;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$accion Ruta"),
          content: Text("¿Seguro que quieres $accion la ruta?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (iniciar) {
                  await routeProvider.startRoute();
                } else {
                  await routeProvider.stopRoute();
                  _stopTimer();
                }
                setState(() {}); // Actualiza la UI
              },
              style: TextButton.styleFrom(foregroundColor: color),
              child: Text(accion),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.brightness == Brightness.dark ? Colors.black87 : Colors.blue[900]!,
                  theme.brightness == Brightness.dark ? Colors.black54 : Colors.blue[300]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Llamamos a _buildCalendar solo si la ruta está activa o no, sin necesidad de botón
                        Consumer<DriverRouteProvider>(builder: (context, routeProvider, child) {
                          if (routeProvider.isRouteActive && routeProvider.pendingUsers.isEmpty) {
                            // La ruta se ha iniciado automáticamente
                          }
                          return _buildCalendar(routeProvider); // Calendario
                        }),
                        const SizedBox(height: 20),
                        Consumer<DriverRouteProvider>(builder: (context, routeProvider, child) {
                          return routeProvider.isRouteActive
                              ? const RouteUserComponent() // Si la ruta está activa, mostramos los usuarios
                              : const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat Component
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ChatComponent(true),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(DriverRouteProvider routeProvider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TableCalendar(
              locale: 'es_ES',
              focusedDay: _focusedDay,
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              calendarFormat: CalendarFormat.week,
              startingDayOfWeek: StartingDayOfWeek.monday,
              selectedDayPredicate: (day) => false,
            ),
            const SizedBox(height: 10),
            // Colocamos los botones dentro del Card
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (!routeProvider.isRouteActive) {
                      _confirmarAccion(true, routeProvider);
                    } else {
                      _confirmarAccion(false, routeProvider);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: routeProvider.isRouteActive ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: Text(routeProvider.isRouteActive ? "Detener Ruta" : "Iniciar Ruta"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
