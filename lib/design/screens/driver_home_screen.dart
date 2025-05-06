import 'dart:async';
import 'package:afa/design/components/chat_component.dart';
import 'package:afa/design/components/route_user_component.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/design/components/side_bar_menu.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:afa/logic/models/notification.dart' as Afa;

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with TickerProviderStateMixin
{
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _isMenuOpen = false;
  void _toggleMenu() {
    setState(() 
    {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _verificarRutaPendiente();
      await Provider.of<AuthUserProvider>(context, listen: false).loadUser();
    });

  }

  Future<void> _verificarRutaPendiente() async {
    final routeProvider = Provider.of<DriverRouteProvider>(context, listen: false);
    if (await routeProvider.canResumeRoute()) 
    {
      await routeProvider.resumeRoute();
      setState(() {});
    }
  }

  Future<void> _confirmarAccion(bool iniciar, DriverRouteProvider routeProvider) async {
  String accion = iniciar ? "Iniciar" : "Detener";
  Color actionColor = iniciar ? Colors.green : Colors.red;

  bool? resultado = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titlePadding: EdgeInsets.zero,
        title: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF063970),
                Color(0xFF2196F3),
              ],
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
              Expanded(
                child: Text(
                  "$accion Ruta",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
        content: Text("¿Seguro que quieres $accion la ruta?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
            ),
            child: Text(accion),
          ),
        ],
      );
    },
  );

  if (resultado == true) {
    if (iniciar) {
      await routeProvider.startRoute();
    } else {
      await routeProvider.stopRoute();
    }
  }
}


  Widget _dayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
  bool isToday = isSameDay(day, DateTime.now());
  bool isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
  bool isFuture = day.isAfter(DateTime.now()) && !isToday && !isWeekend;

  Color bgColor;
  if (isToday) {
    bgColor = Colors.blue;
  } else if (isFuture) {
    bgColor = Colors.green;
  } else {
    bgColor = Colors.grey[400]!;
  }

  BoxDecoration decoration = BoxDecoration(
    color: bgColor,
    shape: BoxShape.circle,
    border: isSameDay(day, _selectedDay) && !isToday
        ? Border.all(color: Colors.blue, width: 2)
        : null,
  );

  // Solo los días con fondo azul o verde serán "clicables"
  bool isClickable = bgColor != Colors.grey[400];

  Widget cell = Container(
    margin: const EdgeInsets.all(4),
    decoration: decoration,
    alignment: Alignment.center,
    child: Text(
      '${day.day}',
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );

  if (isClickable) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: cell,
    );
  } else {
    return cell;
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
          return const ChatComponent();
        },
      ),
    );
  }


Future<void> _showSlidingNotification(BuildContext context, Afa.Notification n) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  final theme = Theme.of(context);

  // Controlador para la animación de entrada y salida
  final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  final animation = Tween<Offset>(begin: const Offset(0, -1), end: const Offset(0, 0))
      .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

  entry = OverlayEntry(
    builder: (_) => Stack(
      children: [
        // Fondo oscuro semitransparente
        const Positioned.fill(
          child: ModalBarrier(
            color: Colors.black54,
            dismissible: false,
          ),
        ),
        // Notificación deslizable clicable
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: animation,
            child: SafeArea(
              bottom: false,
              child: GestureDetector(
                onTap: () async {
                  // Marcar notificación como leída
                  Provider.of<NotificationProvider>(context, listen: false)
                      .markAsReadByNotification(n);
                  // Cerrar la notificación deslizable
                  await controller.reverse();
                  entry.remove();
                  controller.dispose();
                  // Abrir modal de notificaciones
                  _openNotifications();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notifications_active, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              n.message,
                              style: theme.textTheme.bodyLarge!
                                  .copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Icon(Icons.circle, size: 10, color: theme.colorScheme.secondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(n.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.disabledColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // Insertar la notificación en el overlay
  overlay.insert(entry);

  // Devolvemos un Future que completa tras la animación de salida
  return controller.forward().then((_) async {
    await Future.delayed(const Duration(seconds: 1));
    await controller.reverse();
    entry.remove();
    controller.dispose();
  });
}






  @override
  Widget build(BuildContext context) 
  {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
              icon: Icon(_isMenuOpen ? Icons.close : Icons.menu, color: Colors.white),
              onPressed: _toggleMenu,
            ),
            const Spacer(),
            Consumer<NotificationProvider>(
              builder: (_, notificationProvider, __) {
                final count = notificationProvider.notifications.where((n) => !n.isRead).length;
                if (notificationProvider.hasNewNotification) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final n = notificationProvider.latestNotification;
                    _showSlidingNotification(context, n);
                    notificationProvider.markLatestAsShown();

                  });
                }
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
                  theme.brightness == Brightness.dark ? Colors.black87 : Colors.blue[900]!,
                  theme.brightness == Brightness.dark ? Colors.black54 : Colors.blue[300]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Consumer<DriverRouteProvider>(
                      builder: (context, routeProvider, child) => _buildCalendar(routeProvider),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Consumer<DriverRouteProvider>(
                        builder: (context, routeProvider, child) =>
                            routeProvider.isRouteActive
                                ? const SingleChildScrollView(
                                    child: RouteUserComponent(),
                                  )
                                : const SizedBox(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: Container(color: Colors.black54),
              ),
            ),
          if (_isMenuOpen)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SidebarMenu(
                selectedIndex: 0,
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
              onDaySelected: (selectedDay, focusedDay) => setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              }),
              enabledDayPredicate: (day) =>
                  day.weekday >= DateTime.monday && day.weekday <= DateTime.friday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) {
                  String formatted = DateFormat.yMMMM(locale).format(date);
                  return formatted[0].toUpperCase() + formatted.substring(1);
                },
                titleTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isSameDay(_selectedDay, DateTime.now()))
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _selectedDay = DateTime.now();
                      _focusedDay = DateTime.now();
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Hoy"),
                  ),
                if (!isSameDay(_selectedDay, DateTime.now()))
                  const SizedBox(width: 20),
                if (isSameDay(_selectedDay, DateTime.now()))
                  ElevatedButton(
                    onPressed: () => _confirmarAccion(
                      !routeProvider.isRouteActive,
                      routeProvider,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: routeProvider.isRouteActive ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    child: Text(
                      routeProvider.isRouteActive ? "Detener Ruta" : "Iniciar Ruta",
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
