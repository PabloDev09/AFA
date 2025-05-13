import 'dart:async';
import 'dart:ui';
import 'package:afa/design/components/notification_component.dart';
import 'package:afa/design/components/route_user_component.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/design/components/side_bar_menu.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  void initState() 
  {
    super.initState();
    initializeDateFormatting('es', null);
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;

   WidgetsBinding.instance.addPostFrameCallback((_) async 
   {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled || permission == LocationPermission.denied || permission == LocationPermission.deniedForever) 
    {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Debes habilitar el servicio de ubicación"),
          backgroundColor: Colors.red,
        ));
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) 
    {
      await _verificarRutaPendiente(context);
    }

    await Provider.of<AuthUserProvider>(context, listen: false).loadUser();
  });

  }

  Future<void> _verificarRutaPendiente(BuildContext context) async
   {
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
    bgColor = Colors.blueAccent;
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
          return const NotificationComponent();
        },
      ),
    );
  }

Future<void> _showSlidingNotification(
  BuildContext context,
  Afa.Notification n,
) async {
  final overlay = Overlay.of(context); // nada que hacer si no hay Overlay

  final theme = Theme.of(context);

  // 1️⃣ Prepara el reproductor y carga el WAV
  final audioPlayer = AudioPlayer();
  await audioPlayer.setSource(AssetSource('sounds/notification.wav'));

  // 2️⃣ Controlador de animación con vsync válido
  final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  final animation = Tween<Offset>(
    begin: const Offset(0, -1),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(parent: controller, curve: Curves.easeOut),
  );

  // 3️⃣ Construye la OverlayEntry
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Stack(
      children: [
        const Positioned.fill(
          child: ModalBarrier(color: Colors.black54, dismissible: false),
        ),
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: animation,
            child: SafeArea(
              bottom: false,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () async {
                    Provider.of<NotificationProvider>(context, listen: false)
                        .markAsReadByNotification(n);
                    await controller.reverse();
                    entry.remove();
                    controller.dispose();
                    await audioPlayer.dispose();
                    _openNotifications();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                Provider.of<NotificationProvider>(
                                  context,
                                  listen: false,
                                ).markAsReadByNotification(n);
                                await controller.reverse();
                                entry.remove();
                                controller.dispose();
                                await audioPlayer.dispose();
                                _openNotifications();
                              },
                              child: Icon(
                                Icons.notifications_active,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                n.message,
                                style: theme.textTheme.bodyLarge!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: theme.colorScheme.secondary,
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
        ),
      ],
    ),
  );

  // 4️⃣ Inserta la overlay
  overlay.insert(entry);

  // 5️⃣ Retrasa el play y la animación hasta después del build actual
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await audioPlayer.play(AssetSource('sounds/notification.wav'));
    } catch (_) {
      // Silenciar errores de autoplay en web
    }
    await controller.forward();
    await Future.delayed(const Duration(seconds: 1));
    await controller.reverse();

    // 6️⃣ Limpieza
    entry.remove();
    controller.dispose();
    await audioPlayer.dispose();
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
              icon: Icon(_isMenuOpen ? Icons.close : Icons.menu, color: _isMenuOpen ? Colors.blue : Colors.white),
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
                  Consumer<DriverRouteProvider>(
                    builder: (context, routeProvider, child) => 
                      _buildCalendar(routeProvider),
                                      ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Consumer<DriverRouteProvider>(
                        builder: (context, routeProvider, child) {
                        if (routeProvider.isRouteActive) {
                            return const SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.only(top: 20, bottom: 20),
                                child: RouteUserComponent(),
                              ),
                            );
                          } 
                          else 
                          {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    const Icon(
                                      Icons.directions_bus,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No hay ninguna ruta iniciada',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );

                        }
                        },
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
  final bool esHoy = isSameDay(_selectedDay, DateTime.now());

  return ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.2, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: esHoy
                  ? const SizedBox.shrink(key: ValueKey('empty_today'))
                  : TextButton.icon(
                      key: const ValueKey('btn_today'),
                      onPressed: () {
                        setState(() {
                          _selectedDay = DateTime.now();
                          _focusedDay = DateTime.now();
                        });
                      },
                      icon: const Icon(Icons.today, color: Colors.white),
                      label: const Text(
                        'Volver a hoy',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
            ),
          ),
            // — Calendario semanal —
            TableCalendar(
              locale: 'es_ES',
              focusedDay: _focusedDay,
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              calendarFormat: CalendarFormat.week,
              startingDayOfWeek: StartingDayOfWeek.monday,
              onPageChanged: (newFocusedDay) =>
                  setState(() => _focusedDay = newFocusedDay),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
                weekendStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                dowTextFormatter: (date, locale) {
                  final letter =
                      DateFormat.E(locale).format(date)[0].toUpperCase();
                  return date.weekday == DateTime.wednesday ? 'X' : letter;
                },
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: _dayBuilder,
                todayBuilder: _dayBuilder,
                selectedBuilder: _dayBuilder,
                disabledBuilder: _dayBuilder,
              ),
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (sel, foc) =>
                  setState(() {_selectedDay = sel; _focusedDay = foc;}),
              enabledDayPredicate: (day) =>
                  day.weekday >= DateTime.monday &&
                  day.weekday <= DateTime.friday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) {
                  final formatted =
                      DateFormat.yMMMM(locale).format(date);
                  return '${formatted[0].toUpperCase()}${formatted.substring(1)}';
                },
                titleTextStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
                leftChevronIcon:
                    const Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon:
                    const Icon(Icons.chevron_right, color: Colors.white),
              ),
              calendarStyle: const CalendarStyle(
                weekendTextStyle: TextStyle(color: Colors.pinkAccent),
                todayDecoration:
                    BoxDecoration(color: Colors.white38, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlue],
                    ),
                    shape: BoxShape.circle),
                selectedTextStyle: TextStyle(color: Colors.white),
                todayTextStyle: TextStyle(color: Colors.white),
                defaultTextStyle: TextStyle(color: Colors.white),
                disabledTextStyle: TextStyle(color: Colors.white30),
              ),
            ),

            const SizedBox(height: 20),

            // — Panel de acciones —
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInBack,
              layoutBuilder: (cur, prev) => Stack(
                alignment: Alignment.center,
                children: [...prev, if (cur != null) cur],
              ),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: esHoy
                  ? (routeProvider.isRouteActive
                      ? Row(
                          children: [
                            // Botón actualizar
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: routeProvider.isUpdating
                                    ? null
                                    : () async {
                                        setState(() =>
                                            routeProvider.isUpdating = true);
                                        await routeProvider.updateRoute();
                                        setState(() =>
                                            routeProvider.isUpdating = false);
                                      },
                                icon: routeProvider.isUpdating
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.update,
                                        color: Colors.white),
                                      label: Text(
                                        routeProvider.isUpdating
                                            ? 'Actualizando ruta'
                                            : 'Actualizar Ruta',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: routeProvider.isUpdating ? 11 : 14, // 👈 tamaño dinámico
                                        ),
                                      ),

                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Botón detener
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: routeProvider.isLoading
                                    ? null
                                    : () => _confirmarAccion(
                                        false, routeProvider),
                                icon: const Icon(Icons.stop,
                                    color: Colors.white),
                                label: const Text(
                                  'Detener Ruta',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: routeProvider.isLoading
                                ? null
                                : () => _confirmarAccion(true, routeProvider),
                            icon: routeProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow,
                                    color: Colors.white),
                            label: Text(
                              routeProvider.isLoading
                                  ? 'Iniciando ruta'
                                  : 'Iniciar Ruta',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ))
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.play_arrow,
                            color: Colors.grey),
                        label: const Text(
                          'Iniciar Ruta',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
