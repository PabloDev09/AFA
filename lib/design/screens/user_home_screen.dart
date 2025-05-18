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

  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
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
      final authProvider = Provider.of<AuthUserProvider>(context, listen: false);
      await authProvider.loadUser();
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
 
Future<void> _confirmarAccion(bool cancelar,UserRouteProvider userProvider) async 
{
  final username = Provider.of<AuthUserProvider>(context, listen: false)
      .userFireStore
      ?.username;
  if (username == null) return;

  if (_selectedDay.isBefore(DateTime.now()) &&
      !isSameDay(_selectedDay, DateTime.now())) {
    return;
  }

  String accion = cancelar ? "Cancelar" : "Reanudar";
  Color actionColor = cancelar ? Colors.red : Colors.green;

  bool? confirmacion = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        // Aplica la misma curva de borde al diálogo
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // Elimina padding para que el gradiente cubra todo el ancho superior
        titlePadding: EdgeInsets.zero,
        title: Container(
          // Gradiente con bordes superiores redondeados
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
                  "$accion Recogida",
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
        content: Text(
          "¿Seguro que quieres $accion la recogida del día "
          "${DateFormat('dd/MM/yyyy').format(_selectedDay)}?",
        ),
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
            child: const Text("Confirmar"),
          ),
        ],
      );
    },
  );

  if (confirmacion ?? false) {
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
  final isImportant = n.isImportant == true;

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
                      color: isImportant
                          ? Colors.red.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isImportant
                            ? Colors.red
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
                                isImportant
                                    ? Icons.warning_amber_rounded
                                    : Icons.notifications_active,
                                color: isImportant
                                    ? Colors.red
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                n.message,
                                style: theme.textTheme.bodyLarge!.copyWith(
                                  fontWeight: isImportant
                                      ? FontWeight.bold
                                      : FontWeight.bold,
                                  color: isImportant
                                      ? Colors.red[800]
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: isImportant
                                  ? Colors.redAccent
                                  : theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(n.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isImportant
                                ? Colors.red[700]
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
                  Consumer<UserRouteProvider>(
                    builder: (context, routeProvider, child) => 
                      _buildCalendar(routeProvider),
                                      ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Consumer<UserRouteProvider>(
                        builder: (context, routeProvider, child) {
                          if (routeProvider.isRouteActive) {
                            return const SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.only(top: 20, bottom: 20),
                                child: DriverStatusComponent(),
                              ),
                            );
                          } else if (routeProvider.isLoading) {
                            // Mostrar CircularProgress si está cargando
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            );
                          } else {
                            // Mostrar mensaje de "no hay ruta activa"
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
