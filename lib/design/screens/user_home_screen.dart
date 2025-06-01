import 'dart:async';
import 'dart:ui';
import 'package:afa/design/components/driver_status_component.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:afa/design/components/notification_component.dart';
import 'package:afa/design/components/side_bar_menu.dart';
import 'package:afa/logic/models/notification.dart' as Afa;
 
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});
 
  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}
 
class _UserHomeScreenState extends State<UserHomeScreen> with TickerProviderStateMixin 
{
  late DateTime _selectedDay;
  late DateTime _focusedDay;
 
@override
  void initState() 
  {
    super.initState();
    initializeDateFormatting('es', null);
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;

   WidgetsBinding.instance.addPostFrameCallback((_) async 
   {
      final authProvider = Provider.of<AuthUserProvider>(context, listen: false)..loadUser();
      await _verificarRutaPendiente(authProvider.userFireStore?.username);
  });

  } 

 
  Future<void> _verificarRutaPendiente(String? username) async 
  {
    final userRouteProvider = Provider.of<UserRouteProvider>(context, listen: false);

    if (username != null) 
    { 
      if(await userRouteProvider.canResumeRouteUser(username))
      {
        await userRouteProvider.startListening();
      }
      await userRouteProvider.getCancelDates(username);
    }
  }
 
Future<void> _confirmarAccion(bool cancelar, UserRouteProvider userProvider) async {
  final username = Provider.of<AuthUserProvider>(context, listen: false)
      .userFireStore
      ?.username;
  if (username == null) return;

  if (_selectedDay.isBefore(DateTime.now()) &&
      !isSameDay(_selectedDay, DateTime.now())) {
    return;
  }

  final String accion = cancelar ? "Cancelar" : "Reanudar";
  final LinearGradient confirmGradient = cancelar
      ? const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
        colors: [Color(0xFF2E7D32), Color(0xFF66BB6A),],          
        begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  final bool? confirmacion = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16), // padding lateral

      // TITULAR
      title: Container(
        decoration: BoxDecoration(
          gradient: confirmGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$accion Recogida',
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

      // CONTENIDO
      content: Text(
        "¿Seguro que quieres $accion la recogida del día "
        "${DateFormat('dd/MM/yyyy').format(_selectedDay)}?",
        style: const TextStyle(fontSize: 16),
      ),

      // ACCIONES
      actions: [
        Row(
          children: [
            // Botón Cancelar
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

            const SizedBox(width: 20), // más espacio

            // Botón Confirmar con degradado dinámico
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: confirmGradient,
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
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.white.withOpacity(0.2);
                      }
                      return null;
                    }),
                  ),
                  child: const Text(
                    'Confirmar',
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
  );

  if (confirmacion == true) {
    if (cancelar) {
      await userProvider.cancelPickupForDate(username, _selectedDay);
    } else {
      await userProvider.removeCancelPickupForDate(username, _selectedDay);
    }
    await userProvider.getCancelDates(username);
    setState(() {});
  }
}




 
  void _openNotifications() 
  {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return NotificationComponent(scrollController: scrollController);
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


  // Helper widget for each info item
Widget _buildInfoItem({
  required IconData icon,
  required Color iconBgColor,
  required Color iconShadowColor,
  required String label,
}) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: iconShadowColor.withOpacity(0.8),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: Colors.white),
      ),
      const SizedBox(width: 10),
      Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black38,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    ],
  );
}

 
  Widget _dayBuilder(BuildContext context, DateTime day, DateTime focusedDay) 
  {
  final userRouteProvider = Provider.of<UserRouteProvider>(context, listen: false);
  DateTime normalizedDay = DateTime(day.year, day.month, day.day);
  bool isCanceled = userRouteProvider.cancelDates.contains(normalizedDay);
  bool isToday = isSameDay(day, DateTime.now());
  bool isSelected = isSameDay(day, _selectedDay);
  bool isWeekday = day.weekday >= DateTime.monday && day.weekday <= DateTime.friday;
  bool isPast = day.isBefore(DateTime.now()) && !isToday;

  // determina color de fondo
  Color bgColor;
  if (isPast) {
    bgColor = Colors.grey[400]!;
  } else if (isToday) {
    bgColor = Colors.blueAccent;
  } else if (isCanceled) {
    bgColor = Colors.redAccent;
  } else {
    bgColor = isWeekday ? Colors.green : Colors.grey[400]!;
  }

  // texto siempre blanco cuando hay fondo coloreado
  Color textColor = Colors.white;

  BoxDecoration decoration = BoxDecoration(
    color: bgColor,
    shape: BoxShape.circle,
    border: isSelected && !isToday ? Border.all(color: Colors.blue, width: 2) : null,
  );

  // Sólo los días habilitados muestran cursor de clic
  bool isEnabled = !isPast && isWeekday;

  Widget dayCell = Container(
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

  if (isEnabled) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: dayCell,
    );
  } else {
    // días deshabilitados usan cursor por defecto
    return dayCell;
  }
}

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Scaffold(
    drawer: const Drawer(child: SidebarMenu(selectedIndex: 0)),
    extendBodyBehindAppBar: true,
    backgroundColor: Colors.transparent,
    body: Stack(
      children: [
        // Fondo con degradado global
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
        ),
        // Contenido scrollable
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: kToolbarHeight),
                  Consumer<UserRouteProvider>(
                    builder: (context, routeProvider, child) => _buildCalendar(routeProvider),
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Información de ruta',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 21,
                            letterSpacing: 1.1,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(0, 2),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildInfoItem(
                              icon: Icons.alt_route,
                              iconBgColor: Colors.indigo.shade600,
                              iconShadowColor: Colors.indigo.shade800,
                              label: Provider.of<AuthUserProvider>(context, listen: false).userFireStore!.numRoute == 0
                                  ? 'Ruta sin asignar'
                                  : 'Ruta ${Provider.of<AuthUserProvider>(context, listen: false).userFireStore!.numRoute}',
                            ),
                            _buildInfoItem(
                              icon: Icons.location_on,
                              iconBgColor: Colors.cyan.shade600,
                              iconShadowColor: Colors.cyan.shade800,
                              label: Provider.of<AuthUserProvider>(context, listen: false).userFireStore!.numPick == 0
                                  ? 'Parada sin asignar'
                                  : 'Parada ${Provider.of<AuthUserProvider>(context, listen: false).userFireStore!.numPick}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Consumer<UserRouteProvider>(
                  builder: (context, routeProvider, child) {
                    if (routeProvider.isRouteActive) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.0),
                        child: DriverStatusComponent(),
                      );
                    } else if (routeProvider.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      );
                    } else {
                      return SizedBox(
                        height: 300,
                        child: Center(
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
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        // AppBar fijo con degradado transparente
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AppBar(
              backgroundColor: const Color.fromARGB(47, 0, 0, 0),
              elevation: 0,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  tooltip: 'Menú',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: Row(
                children: [
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

                      return Tooltip(
                        message: 'Notificaciones',
                        child: Stack(
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
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCalendar(UserRouteProvider userRouteProvider) {
  return ClipRRect(
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
            // — Botón “Volver a hoy” con AnimatedSwitcher —
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerRight,
                children: [
                  ...previous,
                  if (current != null) current,
                ],
              ),
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.5, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                );
              },
              child: isSameDay(_selectedDay, DateTime.now())
                  ? const SizedBox.shrink(key: ValueKey('todayEmpty'))
                  : Align(
                      key: const ValueKey('todayBtn'),
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 12),

            // — Calendario semanal —
            TableCalendar(
              locale: 'es_ES',
              focusedDay: _focusedDay,
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              calendarFormat: CalendarFormat.week,
              startingDayOfWeek: StartingDayOfWeek.monday,
              onPageChanged: (newFocusedDay) {
                setState(() {
                  _focusedDay = newFocusedDay;
                });
              },
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
              onDaySelected: (sel, foc) {
                setState(() {
                  _selectedDay = sel;
                  _focusedDay = foc;
                });
              },
              enabledDayPredicate: (day) =>
                  day.weekday >= DateTime.monday &&
                  day.weekday <= DateTime.friday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextFormatter: (date, locale) {
                  final f = DateFormat.yMMMM(locale).format(date);
                  return '${f[0].toUpperCase()}${f.substring(1)}';
                },
                titleTextStyle: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
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

            // — Ocultar botones si hay ruta activa hoy —

            // Botón Cancelar / Reanudar
            if (!(userRouteProvider.isRouteActive &&
                  isSameDay(_selectedDay, DateTime.now())))
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInBack,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.center,
                  children: [
                    ...previous,
                    if (current != null) current,
                  ],
                ),
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                  );
                },
                child: Builder(
                  key: ValueKey(_selectedDay),
                  builder: (context) {
                    final isWeekend = _selectedDay.weekday == DateTime.saturday ||
                        _selectedDay.weekday == DateTime.sunday;
                    if (isWeekend) return const SizedBox(height: 42);

                    final isCancelled = userRouteProvider.cancelDates.any((d) =>
                        d.year == _selectedDay.year &&
                        d.month == _selectedDay.month &&
                        d.day == _selectedDay.day);

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _confirmarAccion(!isCancelled, userRouteProvider),
                        icon: Icon(
                          isCancelled ? Icons.refresh : Icons.cancel,
                          color: Colors.white,
                        ),
                        label: Text(
                          isCancelled ? 'Reanudar recogida' : 'Cancelar recogida',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isCancelled ? Colors.green : Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // — Botón “Actualizar Ruta” (solo si hay ruta activa) —
            if (userRouteProvider.isRouteActive && isSameDay(_selectedDay, DateTime.now())) ...[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInBack,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.center,
                  children: [
                    ...previous,
                    if (current != null) current,
                  ],
                ),
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                  );
                },
                child: SizedBox(
                  // ¡Clave basada en isUpdating para que AnimatedSwitcher lo detecte!
                  key: ValueKey(userRouteProvider.isUpdating),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: userRouteProvider.isUpdating
                        ? null
                        : () async {
                            setState(() => userRouteProvider.isUpdating = true);
                            await userRouteProvider.resumeRouteUser(
                              Provider.of<AuthUserProvider>(context, listen: false)
                                  .userFireStore
                                  ?.username,
                            );
                            setState(() => userRouteProvider.isUpdating = false);
                          },
                    icon: userRouteProvider.isUpdating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.update, color: Colors.white),
                    label: Text(
                      userRouteProvider.isUpdating
                          ? 'Actualizando estado'
                          : 'Actualizar estado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: userRouteProvider.isUpdating ? 11 : 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}


}