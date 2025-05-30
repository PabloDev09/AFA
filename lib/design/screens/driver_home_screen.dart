import 'dart:async';
import 'dart:ui';
import 'package:afa/design/components/notice_board_component.dart';
import 'package:afa/design/components/notification_component.dart';
import 'package:afa/design/components/route_user_component.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/design/components/side_bar_menu.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:afa/logic/services/number_route_service.dart';
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

  @override
  void initState() 
  {
    super.initState();
    initializeDateFormatting('es', null);
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;

   WidgetsBinding.instance.addPostFrameCallback((_) async 
   {
    await Provider.of<AuthUserProvider>(context, listen: false).loadUser();
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
  });

  }

  Future<void> _verificarRutaPendiente(BuildContext context) async
   {
    final routeProvider = Provider.of<DriverRouteProvider>(context, listen: false);
    final String? username = Provider.of<AuthUserProvider>(context, listen: false).userFireStore?.username;

    if (await routeProvider.canResumeRoute(username!)) 
    {
      await routeProvider.resumeRoute();
    }
  }

Future<void> _confirmarDetenerRuta(DriverRouteProvider routeProvider) async {
  showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),

      // TITULAR CON DEGRADADO ROJO
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
                'Detener Ruta',
                style: TextStyle(
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

      // CONTENIDO
      content: const Text(
        '¿Seguro que quieres detener la ruta? \n'
        'Esta acción no se puede deshacer y se perderán los datos de la ruta actual.',
        style: TextStyle(fontSize: 16),
      ),

      // ACCIONES
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[800],
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).copyWith(
                    overlayColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.hovered)) {
                        return Colors.white.withOpacity(0.2);
                      }
                      return null;
                    }),
                  ),
                  child: const Text(
                    'Detener',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ).then((resultado) {
    if (resultado == true) {
      routeProvider.stopRoute();
    }
  });
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

Future<void> _showSlidingNotification(
  BuildContext context,
  Afa.Notification n,
) async {
  final overlay = Overlay.of(context);
  final theme = Theme.of(context);
  final isAlert = n.isAlert == true;
  final isImportant = n.isImportant == true;

  // Escoge la ruta del audio según si es alerta, importante o normal
  final audioPath = isAlert
      ? 'sounds/notification-alert.mp3'
      : isImportant
          ? 'sounds/notification-important.mp3'
          : 'sounds/notification.wav';

  // 1️⃣ Prepara el reproductor y carga el audio correcto
  final audioPlayer = AudioPlayer();
  await audioPlayer.setSource(AssetSource(audioPath));

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
                      color: isAlert
                          ? Colors.red.withOpacity(0.1)
                          : isImportant
                              ? Colors.green.withOpacity(0.1)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAlert
                            ? Colors.red
                            : isImportant
                                ? Colors.green
                                : theme.colorScheme.primary,
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
                                isAlert
                                    ? Icons.warning_amber_rounded
                                    : isImportant
                                        ? Icons.check_circle
                                        : Icons.notifications_active,
                                color: isAlert
                                    ? Colors.red
                                    : isImportant
                                        ? Colors.green
                                        : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                n.message,
                                style: theme.textTheme.bodyLarge!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isAlert
                                      ? Colors.red[800]
                                      : isImportant
                                          ? Colors.green[800]
                                          : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: isAlert
                                  ? Colors.redAccent
                                  : isImportant
                                      ? Colors.greenAccent
                                      : theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(n.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isAlert
                                ? Colors.red[700]
                                : isImportant
                                    ? Colors.green[700]
                                    : theme.disabledColor,
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
      await audioPlayer.play(AssetSource(audioPath));
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
      drawer: const Drawer( child: SidebarMenu(selectedIndex: 0),),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white), 
          tooltip: 'Abrir menú',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.feed, color: Colors.white),
              tooltip: 'Tablón',
              onPressed: _openNoticeBoard,
            ),
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
                                          fontSize: routeProvider.isUpdating ? 11 : 14,
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
                                    : () => _confirmarDetenerRuta(routeProvider),
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
                              : () => _showRouteSelectionDialog(routeProvider),
                            icon: routeProvider.isLoading
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 2),
                                )
                              : const Icon(Icons.play_arrow, color: Colors.white),
                            label: Text(
                              routeProvider.isLoading ? 'Iniciando ruta' : 'Iniciar Ruta',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )
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

Future<void> _showRouteSelectionDialog(DriverRouteProvider routeProvider) async {
  final String? username = Provider.of<AuthUserProvider>(context, listen: false)
      .userFireStore
      ?.username;
  if (username == null) return;

  final routes = await NumberRouteService().getDistinctRouteNumbers();
  int? selectedRoute = routes.isNotEmpty ? routes.first : null;

  showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),

      // TITULAR
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
                'Selecciona número de ruta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Cerrar',
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),

      // CONTENIDO
      content: StatefulBuilder(
        builder: (context, setState) {
          return SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
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
                  items: routes
                      .map((n) => DropdownMenuItem(
                            value: n,
                            child: Row(
                              children: [
                                const Icon(Icons.alt_route, color: Colors.indigo),
                                const SizedBox(width: 8),
                                Text('Ruta $n'),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (n) => setState(() => selectedRoute = n),
                ),
              ),
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
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                  onPressed: () {
                    if (selectedRoute == null) return;
                    Navigator.pop(context, true);
                    routeProvider.startRoute(username, selectedRoute!);
                    setState(() {}); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).copyWith(
                    overlayColor:
                        WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.white.withOpacity(0.2);
                      }
                      return null;
                    }),
                  ),
                  child: const Text(
                    'Iniciar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ).then((confirmed) {
    if (confirmed == true && selectedRoute != null) {
      // el startRoute ya se llamó en el onPressed, pero si prefieres hacerlo aquí:
      // routeProvider.startRoute(username, selectedRoute!);
      setState(() {});
    }
  });
}



}