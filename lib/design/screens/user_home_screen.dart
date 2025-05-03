import 'dart:async';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:afa/design/components/chat_component.dart';
import 'package:afa/design/components/side_bar_menu.dart';
 
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});
 
  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}
 
class _UserHomeScreenState extends State<UserHomeScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  bool _hasShownPickupAlert = false;
  late Future<void> _initialLoad;
  late Timer _timer;
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }
 
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
 
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
      });
    });
 
    // Carga de datos diferida para evitar errores al usar Provider
    _initialLoad = Future<void>(() async {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    });
  }
 
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
 

 
  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthUserProvider>(context, listen: false);
    final userRouteProvider =
        Provider.of<UserRouteProvider>(context, listen: false);
 
    await authProvider.loadUser();
    final username = authProvider.userFireStore?.username;
    if (username != null) {
      userRouteProvider.startListening(username);
      await userRouteProvider.getCancelDates(username);
    }
  }
 
  Future<void> _confirmarAccion(
      bool cancelar, UserRouteProvider userProvider) async {
    final username = Provider.of<AuthUserProvider>(context, listen: false)
        .userFireStore
        ?.username;
    if (username == null) return;
 
    if (_selectedDay.isBefore(DateTime.now()) &&
        !isSameDay(_selectedDay, DateTime.now())) {
      return;
    }
 
    String accion = cancelar ? "Cancelar" : "Reanudar";
    Color color = cancelar ? Colors.red : Colors.blue;
 
    bool? confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("$accion Recogida"),
          content: Text(
              "¿Seguro que quieres $accion la recogida del día ${DateFormat('dd/MM/yyyy').format(_selectedDay)}?"),
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
        await userProvider.cancelPickupForDate(username, _selectedDay);
      } else {
        await userProvider.removeCancelPickup(username, _selectedDay);
      }
 
      await userProvider.getCancelDates(username);
      setState(() {});
    }
  }
 
  void _openNotifications() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return ChatComponent(scrollController: scrollController);
      },
    ),
  );
}


  // Nuevo método para cancelar la recogida actual
  Future<void> _cancelarRecogidaActual(UserRouteProvider userProvider) async {
    final username =
        Provider.of<AuthUserProvider>(context, listen: false).userFireStore?.username;
    if (username == null) return;
 
    bool? confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cancelar recogida actual"),
          content: const Text("¿Estás seguro de que quieres cancelar la recogida actual? Serás eliminado de la ruta."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text("Sí, cancelar"),
            ),
          ],
        );
      },
    );
 
    if (confirmacion ?? false) {
      await userProvider.cancelCurrentPickup(username);
      setState(() {});
    }
  }
 
  // Método para construir el día del calendario
  Widget _dayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    final userRouteProvider =
        Provider.of<UserRouteProvider>(context, listen: false);
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    bool isCanceled = userRouteProvider.cancelDates.contains(normalizedDay);
    bool isToday = isSameDay(day, DateTime.now());
    bool isSelected = isSameDay(day, _selectedDay);
    bool isWeekday =
        day.weekday >= DateTime.monday && day.weekday <= DateTime.friday;
    bool isPast = day.isBefore(DateTime.now()) && !isToday;
 
    Color bgColor;
    Color textColor;
 
    if (isPast) {
      bgColor = isCanceled ? Colors.red : Colors.grey;
      textColor = Colors.white;
    } else {
      if (isToday) {
        bgColor = Colors.blue;
        textColor = (day.weekday == DateTime.saturday ||
                day.weekday == DateTime.sunday)
            ? Colors.white
            : Colors.grey[600]!;
      } else {
        if (isCanceled) {
          bgColor = Colors.red;
          textColor = Colors.white;
        } else {
          bgColor = isWeekday ? Colors.green : Colors.grey[400]!;
          textColor = Colors.white;
        }
      }
    }
 
    BoxDecoration decoration = BoxDecoration(
      color: bgColor,
      shape: BoxShape.circle,
      border: isSelected && !isToday
          ? Border.all(color: Colors.blue, width: 2)
          : null,
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
    return FutureBuilder<void>(
      future: _initialLoad,
      builder: (context, snapshot) {
        return Consumer<UserRouteProvider>(
          builder: (context, userRouteProvider, _) {
            if (userRouteProvider.previousIsNearToPickUpUser &&
                !_hasShownPickupAlert) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("¡Atención!"),
                      content: const Text(
                          "¡El conductor está a 5 minutos! ¡Ve al punto de recogida!"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _hasShownPickupAlert = true;
                            });
                          },
                          child: const Text("Aceptar"),
                        ),
                      ],
                    );
                  },
                );
              });
            }
            return buildMainContent(userRouteProvider);
          },
        );
      },
    );
  }
 
  Widget buildMainContent(UserRouteProvider userRouteProvider) {
    final theme = Theme.of(context);
    return Scaffold(
        appBar: AppBar(
    backgroundColor: _isMenuOpen ? Color.fromARGB(30,0,0,0) : Colors.blue[300],
    elevation: 0,
    title: Row(
      children: [
        IconButton(
          icon: Icon(_isMenuOpen ? Icons.close : Icons.menu,
                      color: _isMenuOpen ? Colors.blue[700] : Colors.white),
          onPressed: _toggleMenu,
        ),
        const Spacer(),
        Consumer<NotificationProvider>(
        builder: (_, notificationProvider, __) {
          final count = notificationProvider.notifications.where((n)=>!n.isRead).length;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: _openNotifications,
              ),
              if (count > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),

      ],
    ),
    ),
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
            child: Padding(
              padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top),
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
                              'Bienvenido, ${Provider.of<AuthUserProvider>(context, listen: true).userFireStore?.name ?? ''} ${Provider.of<AuthUserProvider>(context, listen: true).userFireStore?.surnames ?? ''}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildCalendar(userRouteProvider),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  const ChatComponent(),
                ],
              ),
            ),
          ),
          // Capa oscura si el menú está abierto
      if (_isMenuOpen)
        Positioned.fill(
          child: GestureDetector(
            onTap: _toggleMenu,
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        ),

      // Sidebar visible
      if (_isMenuOpen)
         Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SidebarMenu(selectedIndex: 0, userName: '${Provider.of<AuthUserProvider>(context, listen: true).userFireStore?.name ?? ''} ${Provider.of<AuthUserProvider>(context, listen: true).userFireStore?.surnames ?? ''}'),
        ),
        ],
      ),
    );
  }
 
  Widget _buildCalendar(UserRouteProvider userRouteProvider) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
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
              enabledDayPredicate: (day) =>
                  day.weekday >= DateTime.monday && day.weekday <= DateTime.friday,
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
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                bool isPast = _selectedDay.isBefore(DateTime.now()) &&
                    !isSameDay(_selectedDay, DateTime.now());
                bool isToday = isSameDay(_selectedDay, DateTime.now());
                bool isWeekendToday = DateTime.now().weekday == DateTime.saturday ||
                    DateTime.now().weekday == DateTime.sunday;
                if (isPast || (isToday && isWeekendToday)) {
                  return const SizedBox(height: 42);
                }
                bool isCancelled = userRouteProvider.cancelDates.contains(
                  DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day),
                );
 
                List<Widget> buttons = [];
 
                if (isCancelled) {
                  buttons.add(
                    ElevatedButton(
                      onPressed: () => _confirmarAccion(false, userRouteProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text("Reanudar Recogida"),
                    ),
                  );
                } else {
                  buttons.add(
                    ElevatedButton(
                      onPressed: () => _confirmarAccion(true, userRouteProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text("Cancelar Recogida"),
                    ),
                  );
                }
                final username = Provider.of<AuthUserProvider>(context, listen: false).userFireStore?.username;
                FutureBuilder<bool>(
                  future: userRouteProvider.checkIfUserIsBeingPicked(username!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data == true) {
                      return ElevatedButton(
                        onPressed: () => _cancelarRecogidaActual(userRouteProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: const Text("Cancelar Recogida Actual"),
                      );
                    }
                    return Container();
                  },
                );
                return Column(children: buttons);
              },
            ),
          ],
        ),
      ),
    );
  }
}
