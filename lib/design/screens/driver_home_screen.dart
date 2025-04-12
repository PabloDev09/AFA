import 'dart:async';
import 'package:afa/design/components/chat_component.dart';
import 'package:afa/design/components/route_user_component.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Timer _timer;
  bool isNotDriver = false; // Cambiar este valor según si el usuario es conductor o no

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay; // Inicializamos el día seleccionado
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

  /// Método _dayBuilder modificado:
  /// - Si es hoy: azul.
  /// - Si es sábado o domingo: gris (igual que días pasados).
  /// - Si es día futuro y no es fin de semana: verde.
  /// - Días pasados: gris.
  Widget _dayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    bool isToday = isSameDay(day, DateTime.now());
    bool isSelected = isSameDay(day, _selectedDay);
    // Determinar si el día es fin de semana.
    bool isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    // Se considera día futuro solo si no es fin de semana.
    bool isFuture = day.isAfter(DateTime.now()) && !isToday && !isWeekend;

    Color bgColor;
    if (isToday) {
      bgColor = Colors.blue;
    } else if (isFuture) {
      bgColor = Colors.green;
    } else {
      bgColor = Colors.grey[400]!;
    }
    Color textColor = Colors.white;
    BoxDecoration decoration = BoxDecoration(
      color: bgColor,
      shape: BoxShape.circle,
      border: isSelected && !isToday ? Border.all(color: Colors.blue, width: 2) : null,
    );
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: decoration,
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
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
                        // Calendario similar al de UserHomeScreen.
                        Consumer<DriverRouteProvider>(
                          builder: (context, routeProvider, child) {
                            return _buildCalendar(routeProvider);
                          }
                        ),
                        const SizedBox(height: 20),
                        Consumer<DriverRouteProvider>(
                          builder: (context, routeProvider, child) {
                            return routeProvider.isRouteActive
                                ? const RouteUserComponent() 
                                : const SizedBox.shrink();
                          }
                        ),
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
            child: ChatComponent(),
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
            // Botón "Hoy" para actualizar la selección si no se ha seleccionado el día actual.
            if (!isSameDay(_selectedDay, DateTime.now()))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDay = DateTime.now();
                      _focusedDay = DateTime.now();
                    });
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Hoy"),
                ),
              ),
            TableCalendar(
              locale: 'es_ES',
              focusedDay: _focusedDay,
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              calendarFormat: CalendarFormat.week,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: _dayBuilder,
                todayBuilder: _dayBuilder,
                selectedBuilder: _dayBuilder,
                disabledBuilder: _dayBuilder,
              ),
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              // Se deshabilitan los sábados y domingos.
              enabledDayPredicate: (day) =>
                  day.weekday >= DateTime.monday && day.weekday <= DateTime.friday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) {
                  String formattedDate = DateFormat.yMMMM(locale).format(date);
                  return formattedDate[0].toUpperCase() + formattedDate.substring(1);
                },
                titleTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Mostrar el botón solo si el día seleccionado es el día actual.
            if (isSameDay(_selectedDay, DateTime.now()))
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
                      // Se muestra en verde si se va a iniciar la ruta y el día es hoy;
                      // de lo contrario, se muestra en rojo si la ruta ya está activa.
                      backgroundColor: routeProvider.isRouteActive ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: Text(routeProvider.isRouteActive ? "Detener Ruta" : "Iniciar Ruta"),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
