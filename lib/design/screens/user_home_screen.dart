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

  // Para simular las fechas canceladas (puedes reemplazarlo con tu lógica real)
  final Set<DateTime> _cancelledPickups = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
  }

  Future<void> loadUserData() async {
    final username = Provider.of<AuthUserProvider>(context, listen: false).userFireStore?.username;
    if (username != null) {
      Provider.of<UserRouteProvider>(context, listen: false).startListening(username);
    }
  }

  Future<void> _confirmarAccion(bool cancelar, UserRouteProvider userProvider) async {
    final username = Provider.of<AuthUserProvider>(context, listen: false).userFireStore?.username;
    if (username == null) return;

    String accion = cancelar ? "Cancelar" : "Reanudar";
    Color color = cancelar ? Colors.red : Colors.blue;

    bool? confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$accion Recogida"),
          content: Text("¿Seguro que quieres $accion la recogida del día ${DateFormat('dd/MM/yyyy').format(_selectedDay)}?"),
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
        setState(() {
          _cancelledPickups.add(_selectedDay); // Marcar como cancelado
        });
        await userProvider.cancelPickupForDate(username, _selectedDay);
      } else {
        setState(() {
          _cancelledPickups.remove(_selectedDay); // Eliminar la cancelación
        });
        await userProvider.removeCancelPickup(username, _selectedDay);
      }
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: Provider.of<AuthUserProvider>(context, listen: true).loadUser(),
      builder: (context, snapshot) {
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Bienvenido, ${Provider.of<AuthUserProvider>(context, listen: true).userFireStore?.name ?? ''} ${Provider.of<AuthUserProvider>(context, listen: true).userFireStore?.surnames ?? ''}',
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
                      ],
                    ),
                  ),
                ),
                const ChatComponent(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
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
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              enabledDayPredicate: (day) => day.weekday >= 1 && day.weekday <= 5, // Solo lunes a viernes
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) {
                  String formattedDate = DateFormat.yMMMM(locale).format(date);
                  return formattedDate[0].toUpperCase() + formattedDate.substring(1);
                },
                titleTextStyle:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: _cancelledPickups.contains(DateTime.now())
                      ? Colors.red // Día actual cancelado
                      : Colors.orange, // Día actual normal
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.blue, // Día seleccionado en azul
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(fontSize: 18, color: Colors.white),
                // Marcar los días cancelados en rojo y los programados en verde
                defaultDecoration: BoxDecoration(
                  color: _cancelledPickups.contains(_selectedDay)
                      ? Colors.red // Día con recogida cancelada
                      : Colors.green, // Día con recogida programada
                  shape: BoxShape.circle,
                ),
                weekendDecoration: BoxDecoration(
                  color: _cancelledPickups.contains(_selectedDay)
                      ? Colors.red
                      : Colors.green,
                  shape: BoxShape.circle,
                ),
                // Aseguramos que el texto sea blanco en los días con fondo
                defaultTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            // Colocamos los botones dentro del Card
            Consumer<UserRouteProvider>(
              builder: (context, userProvider, _) {
                return _cancelledPickups.contains(_selectedDay)
                    ? ElevatedButton(
                        onPressed: () => _confirmarAccion(false, userProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: const Text("Reanudar Recogida"),
                      )
                    : ElevatedButton(
                        onPressed: () => _confirmarAccion(true, userProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: const Text("Cancelar Recogida"),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
