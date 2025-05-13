import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Muestra el estado del conductor con un GIF de autobús animado sobre la barra de progreso,
/// la distancia y tiempo restante, ETA rango +5 min, y opciones para cancelar o reanudar.
class DriverStatusComponent extends StatelessWidget 
{
  const DriverStatusComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width <= 500;
    return Consumer<UserRouteProvider>(
      builder: (context, routeProvider, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation);
                      return SlideTransition(
                        position: offsetAnimation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: routeProvider.isRouteActive
                        ? _buildUserStatusCard(context, routeProvider, isCompact)
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ),
              ],
            );
          },
        );
      }
}

Widget _buildUserStatusCard(
  BuildContext context,
  UserRouteProvider userRouteProvider,
  bool isCompact,
) {
  final user = userRouteProvider.routeUser;
  final isOtherBeingPicked = userRouteProvider.isOtherBeingPicked;

  final mins = user.distanceInMinutes;
  final hours = mins ~/ 60;
  final remMins = mins % 60;
  final formattedTime = [
    if (hours > 0) '${hours}h',
    '${remMins}min',
  ].join(' ');

  final distanceKm = user.distanceInKm.toStringAsFixed(1);
  final now = DateTime.now();
  final etaStart = now.add(Duration(minutes: mins));
  final etaEnd = etaStart.add(const Duration(minutes: 5));
  double progress = ((15 - mins) / 15).clamp(0.0, 1.0);

  Color borderColor = Colors.orangeAccent;
  String title = 'Conductor ocupado';
  String message = 'Está recogiendo a otro usuario.';
  IconData icon = Icons.access_time_filled;
  Color fillColor = Colors.grey;


  if (user.isCancelled) {
    borderColor = Colors.redAccent;
    title = 'Recogida cancelada';
    message = 'Has cancelado tu recogida.';
    icon = Icons.cancel;
    progress = 1.0; // Progreso al 100% cuando se cancela
    fillColor = Colors.red; // Color rojo para cancelado
  } else if (user.isCollected) {
    borderColor = Colors.green;
    title = 'Recogida completada';
    message = 'Has sido recogido.';
    icon = Icons.check_circle;
    progress = 1.0; // Progreso al 100% cuando se completa
    fillColor = Colors.green; // Color verde para completado
  } else if (user.isBeingPicking) {
    borderColor = Colors.blueAccent;
    title = 'Conductor en camino';
    message = 'El conductor va hacia ti.';
    icon = Icons.directions_bus;
  } else if (isOtherBeingPicked) {
    borderColor = Colors.orangeAccent;
    title = 'Conductor ocupado';
    message = 'Está recogiendo a otro usuario.';
    icon = Icons.access_time_filled;
  }

  final busWidth = isCompact ? 30.0 : 50.0;

  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 300), // Duración de la transición
    child: Card(
      key: ValueKey(user), // La clave debe cambiar con el usuario para activar la transición
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor.withOpacity(0.6), width: 2),
      ),
      elevation: 6,
      shadowColor: borderColor.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: borderColor.withOpacity(0.2),
                  radius: isCompact ? 20 : 28,
                  child: Icon(icon, color: borderColor, size: isCompact ? 20 : 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 14 : 16,
                          color: borderColor,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                message,
                key: ValueKey(message), // Añadimos la clave para activar la transición
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: isCompact ? 12 : 14,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            // Mostrar distancia y tiempo solo si no está cancelado o completado
            if (!user.isCancelled && !user.isCollected) ...[
              Row(
                  children: [
                    Icon(Icons.social_distance, size: isCompact ? 16 : 20, color: const Color.fromARGB(255, 0, 0, 0)),
                    const SizedBox(width: 8),
                    Text(
                      'Distancia estimada:',
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          distanceKm == '0.0' ? 'No disponible' : '$distanceKm km',
                          key: ValueKey(distanceKm),
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: isCompact ? 12 : 14,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Tiempo
                Row(
                  children: [
                    Icon(Icons.access_time, size: isCompact ? 16 : 20, color: const Color.fromARGB(255, 0, 0, 0)),
                    const SizedBox(width: 8),
                    Text(
                      'Tiempo estimado:',
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          formattedTime.isEmpty ? 'No disponible' : formattedTime,
                          key: ValueKey(formattedTime),
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                fontSize: isCompact ? 11 : 13,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
            ],
            SizedBox(
              height: busWidth + (isCompact ? 4 : 8),
              child: LayoutBuilder(builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                final left = progress * (barWidth - busWidth);
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: busWidth / 2 - (isCompact ? 3 : 5),
                      child: Container(
                        height: isCompact ? 6 : 10,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      width: progress * barWidth,
                      top: busWidth / 2 - (isCompact ? 3 : 5),
                      child: Container(
                        height: isCompact ? 6 : 10,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Positioned(
                      left: left,
                      top: 0,
                      child: Image.asset(
                        'assets/images/autobus-unscreen.gif',
                        width: busWidth,
                        height: busWidth * 0.6,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 8),
            // Mostrar la hora de llegada solo si no está cancelado o completado
            if (!user.isCancelled && !user.isCollected) ...[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Align(
                  alignment: Alignment.centerRight,
                  key: ValueKey(etaStart), // Cambiar clave cuando el tiempo de llegada cambie
                  child: Text(
                    'Llegada: '
                    '${etaStart.hour.toString().padLeft(2, '0')}:' 
                    '${etaStart.minute.toString().padLeft(2, '0')}'
                    ' – '
                    '${etaEnd.hour.toString().padLeft(2, '0')}:' 
                    '${etaEnd.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Mostrar botones solo si no está cancelado ni recogido
            if (!user.isCollected) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: user.isCancelled
                          ? null
                          : () => _showConfirmation(
                                context,
                                'Cancelar Recogida',
                                '¿Seguro que quieres cancelar la recogida?',
                                () {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    userRouteProvider.cancelCurrentPickup();
                                  });
                                },
                                Colors.redAccent,
                              ),
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text('Cancelar Recogida', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        textStyle: TextStyle(fontSize: isCompact ? 12 : 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: user.isCancelled
                          ? () => _showConfirmation(
                                context,
                                'Reanudar Recogida',
                                '¿Quieres reanudar la recogida?',
                                () {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    userRouteProvider.removeCurrentPickup();
                                  });
                                },
                                Colors.green,
                              )
                          : null,
                      icon: const Icon(Icons.undo, color: Colors.white),
                      label: const Text('Reanudar Recogida', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        textStyle: TextStyle(fontSize: isCompact ? 12 : 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}







Future<void> _showConfirmation(
  BuildContext context,
  String title,
  String content,
  VoidCallback onConfirm,
  Color confirmColor,
) async {
  final resultado = await showDialog<bool>(
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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              title.contains('Cancelar') ? 'Cancelar' : 'Confirmar',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );

  if (resultado == true) 
  {
    onConfirm();
  }
}