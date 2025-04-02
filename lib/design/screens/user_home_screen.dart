import 'dart:async';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:afa/design/components/chat_component.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  late String _horaRecogida;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay; // Día actual fijo
    _horaRecogida = DateFormat('HH:mm:ss').format(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _horaRecogida = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    });

    // Iniciamos la carga de datos necesarios
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// Carga los datos necesarios para la pantalla.
  Future<void> loadUserData() async {
    // Ejemplo: iniciar el listener del UserRouteProvider
    Provider.of<UserRouteProvider>(context, listen: false).startListening("pepe");
    // Puedes agregar aquí más carga de datos si fuera necesario.
  }

  Future<void> _confirmarAccion(
      bool cancelar, UserRouteProvider userProvider) async {
    String accion = cancelar ? "Cancelar" : "Reanudar";
    Color color = cancelar ? Colors.red : Colors.blue;

    bool? confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$accion Recogida"),
          content: Text("¿Seguro que quieres $accion la recogida?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: color),
              child: Text(accion),
            ),
          ],
        );
      },
    );

    if (confirmacion ?? false) {
      if (cancelar) {
        await userProvider.cancelPickup();
        userProvider.addNotification("Recogida cancelada");
      } else {
        await userProvider.resumePickup();
        userProvider.addNotification("Recogida reanudada");
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: Provider.of<AuthUserProvider>(context,listen: true).loadUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done && snapshot.connectionState != ConnectionState.active) {
        }
        return buildMainContent();
      },
    );
  }

  Widget buildMainContent() {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.brightness == Brightness.dark
                      ? Colors.black87
                      : Colors.blue[900]!,
                  theme.brightness == Brightness.dark
                      ? Colors.black54
                      : Colors.blue[300]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        vertical: 60, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Bienvenido, ${Provider.of<AuthUserProvider>(context,listen: true).userFireStore?.name} ${Provider.of<AuthUserProvider>(context,listen: true).userFireStore?.surnames}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildCalendar(),
                        const SizedBox(height: 20),
                        Consumer<UserRouteProvider>(
                          builder: (context, userProvider, child) {
                            return userProvider.isPickupScheduled
                                ? _buildPickupInfo(userProvider)
                                : _buildPickupCancelled(userProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const ChatComponent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          locale: 'es_ES',
          focusedDay: _focusedDay,
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          calendarFormat: CalendarFormat.week,
          startingDayOfWeek: StartingDayOfWeek.monday,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          enabledDayPredicate: (_) => false,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextFormatter: (date, locale) {
              String formattedDate = DateFormat.yMMMM(locale).format(date);
              return formattedDate[0].toUpperCase() +
                  formattedDate.substring(1);
            },
            titleTextStyle:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          calendarStyle: const CalendarStyle(
            todayDecoration:
                BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
            todayTextStyle:
                TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildPickupInfo(UserRouteProvider userProvider) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Recogida Programada',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Hora de recogida: $_horaRecogida',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _confirmarAccion(true, userProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 50, vertical: 20),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text("Cancelar Recogida"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupCancelled(UserRouteProvider userProvider) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Recogida Cancelada',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _confirmarAccion(false, userProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 50, vertical: 20),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text("Reanudar Recogida"),
            ),
          ],
        ),
      ),
    );
  }
}
