import 'dart:async';
import 'package:afa/design/components/route_user_component.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late DateTime _fechaInicioRuta;
  late String _horaActual;
  final DateTime _focusedDay = DateTime.now();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
    _horaActual = DateFormat('HH:mm:ss').format(DateTime.now());
    _fechaInicioRuta = DateTime.now(); // Inicialización predeterminada
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

 Future<void> _confirmarAccion(bool iniciar, DriverRouteProvider routeProvider) async {
  String accion = iniciar ? "Iniciar" : "Detener";
  Color color = iniciar ? Colors.blue : Colors.red;

  showDialog<bool>(context: context, builder: (context) {
    return AlertDialog(
      title: Text("$accion Ruta"),
      content: Text("¿Seguro que quieres $accion la ruta?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        TextButton(
          onPressed: () async {
            if (iniciar) {
              _fechaInicioRuta = DateTime.now(); // Guardamos la fecha cuando se inicia la ruta
              await routeProvider.startRoute();
              _startTimer();
            } else {
              await routeProvider.stopRoute();
              routeProvider.isLoading = false;
              _stopTimer();
            }

            // Aseguramos de cerrar el diálogo después de realizar las acciones
            Navigator.pop(context); // Cierra el AlertDialog
            setState(() {}); // Actualiza el estado del widget
          },
          style: TextButton.styleFrom(foregroundColor: color),
          child: Text(accion),
        ),
      ],
    );
  });
}


  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _horaActual = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    });
  }

  void _stopTimer() {
    _timer.cancel();
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
                        Consumer<DriverRouteProvider>(builder: (context, routeProvider, child) {
                          if (routeProvider.rutaIniciada && routeProvider.usersToPickUp.isEmpty) {
                            _confirmarAccion(false, routeProvider);  // Detener la ruta si no hay usuarios
                          }

                          return routeProvider.rutaIniciada
                              ? _buildRutaIniciada(routeProvider)
                              : _buildCalendar(routeProvider);
                        }),
                        const SizedBox(height: 20),
                        Consumer<DriverRouteProvider>(builder: (context, routeProvider, child) {
                          return routeProvider.rutaIniciada
                              ? const RouteUserComponent()
                              : const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
            Stack(
              children: [
                TableCalendar(
                  locale: 'es_ES',
                  focusedDay: _focusedDay,
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2100),
                  calendarFormat: CalendarFormat.week,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (day) => false,
                  onDaySelected: (selectedDay, focusedDay) {},
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextFormatter: (date, locale) {
                      String formattedDate = DateFormat.yMMMM(locale).format(date);
                      return formattedDate[0].toUpperCase() + formattedDate.substring(1);
                    },
                    leftChevronVisible: false,
                    rightChevronVisible: false,
                    titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    weekendStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
                if (routeProvider.isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Centrado de los botones
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (!routeProvider.rutaIniciada) {
                      _confirmarAccion(true, routeProvider);
                    } else {
                      _confirmarAccion(false, routeProvider);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: routeProvider.rutaIniciada ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: Text(routeProvider.rutaIniciada ? "Detener Ruta" : "Iniciar Ruta"),
                ),
                const SizedBox(width: 20),
                FutureBuilder<bool>(
                  future: routeProvider.canContinueRoute(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    } else if (snapshot.hasData && snapshot.data!) {
                      routeProvider.isLoading = true;
                      return ElevatedButton(
                        onPressed: () {
                          routeProvider.continueRoute();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,  // Botón verde
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: const Text("Continuar Ruta"),
                      );
                    } else {
                      return const SizedBox.shrink();  // Si no se puede continuar, no mostramos el botón
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRutaIniciada(DriverRouteProvider routeProvider) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                'Ruta iniciada: ${DateFormat('d MMMM y', 'es_ES').format(_fechaInicioRuta)}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                _horaActual,
                style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _confirmarAccion(false, routeProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text("Detener Ruta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
