import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Muestra el estado del conductor con un GIF de autobús animado sobre la barra de progreso,
/// la distancia y tiempo restante, ETA rango +5 min, y opciones para cancelar o reanudar.
class DriverStatusComponent extends StatelessWidget {
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
  final driver = userRouteProvider.routeDriver;
  final hasProblem = userRouteProvider.hasProblem;
  final isOtherBeingPicked = userRouteProvider.isOtherBeingPicked;

  // Cálculo de paradas restantes antes de tu recogida
  final driverPick = driver.numPick;
  final userPick = user.numPick;
  int stopsRemaining;
  if (driverPick == 0) {
    stopsRemaining = userPick;
  } else {
    stopsRemaining = userPick - driverPick;
    if (stopsRemaining < 0) stopsRemaining = 0;
  }

  String pickOrderMessage = '';
  if (!user.isCancelled && !user.isCollected && !user.isBeingPicking) {
    if (stopsRemaining == 1) {
      pickOrderMessage = 'Eres el primero en ser recogido';
    } else if (stopsRemaining == 2) {
      pickOrderMessage = 'Eres el siguiente';
    } else if (stopsRemaining > 2) {
      pickOrderMessage = 'Quedan $stopsRemaining paradas antes de ti';
    }
  }

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

  // Adaptative spacing
  final spacing = isCompact ? 8.0 : 16.0;
  final busWidth = isCompact ? 30.0 : 50.0;

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
    progress = 1.0;
    fillColor = Colors.red;
  } else if (user.isCollected) {
    borderColor = Colors.green;
    title = 'Recogida completada';
    message = 'Has sido recogido.';
    icon = Icons.check_circle;
    progress = 1.0;
    fillColor = Colors.green;
  } else if (hasProblem) {
    borderColor = Colors.red;
    title = 'Incidencia en la ruta';
    message = 'El conductor ha reportado un problema. Por favor espera indicaciones.';
    icon = Icons.warning_amber_rounded;
    fillColor = Colors.redAccent;
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

  return AnimatedSwitcher(
    key: ValueKey(user),
    duration: const Duration(milliseconds: 300),
    child: Card(
      key: ValueKey(user),
      margin: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing / 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor.withOpacity(0.6), width: 2),
      ),
      elevation: 6,
      shadowColor: borderColor.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) Banner de incidencia
            if (hasProblem && !user.isCollected) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: spacing / 2, horizontal: spacing),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  border: Border.all(color: Colors.redAccent, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.redAccent, semanticLabel: 'Alerta de incidencia'),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Incidencia reportada en la ruta',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacing),
            ],

            // 2) Información del conductor + botón llamar
            if (!user.isCollected) ...[
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueGrey.withOpacity(0.1),
                    radius: isCompact ? 16 : 20,
                    child: const Icon(Icons.person,
                        color: Colors.blueGrey, semanticLabel: 'Icono conductor'),
                  ),
                  SizedBox(width: spacing / 2),
                  Expanded(
                    child: Text(
                      '${driver.name} ${driver.surnames}',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Llamar al conductor',
                    child: IconButton(
                      icon: Icon(Icons.call, size: isCompact ? 20 : 24),
                      color: Colors.green,
                      onPressed: () async {
                        final uri = Uri(scheme: 'tel', path: driver.phoneNumber);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo iniciar la llamada')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacing),
            ],

            // 3) Icono + título
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: borderColor.withOpacity(0.2),
                  radius: isCompact ? 20 : 28,
                  child: Icon(icon, color: borderColor, size: isCompact ? 20 : 30),
                ),
                SizedBox(width: spacing),
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
            SizedBox(height: spacing / 2),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: isCompact ? 12 : 14,
                  ),
            ),
            
            // 4) Mensaje de posición de parada
            if (pickOrderMessage.isNotEmpty) ...[
              SizedBox(height: spacing / 2),
              Text(
                pickOrderMessage,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: isCompact ? 12 : 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
              ),
              SizedBox(height: spacing),
            ],

            // 5) Distancia y tiempo
            if (!user.isCancelled && !user.isCollected && !hasProblem) ...[
              Row(
                children: [
                  Icon(Icons.social_distance,
                      size: isCompact ? 16 : 20, color: Colors.black87),
                  SizedBox(width: spacing / 2),
                  Text('Distancia estimada:',
                      style: TextStyle(
                          fontSize: isCompact ? 12 : 14,
                          fontWeight: FontWeight.w500)),
                  SizedBox(width: spacing / 4),
                  Text(
                    distanceKm == '0.0' ? 'No disponible' : '$distanceKm km',
                    style: TextStyle(fontSize: isCompact ? 12 : 14),
                  ),
                ],
              ),
              SizedBox(height: spacing / 2),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: isCompact ? 16 : 20, color: Colors.black87),
                  SizedBox(width: spacing / 2),
                  Text('Tiempo estimado:',
                      style: TextStyle(
                          fontSize: isCompact ? 12 : 14,
                          fontWeight: FontWeight.w500)),
                  SizedBox(width: spacing / 4),
                  Text(
                    formattedTime.isEmpty ? 'No disponible' : formattedTime,
                    style: TextStyle(fontSize: isCompact ? 11 : 13),
                  ),
                ],
              ),
              SizedBox(height: spacing),
            ],

            // 6) Barra de progreso + GIF
            if (!user.isCollected) ...[
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
              SizedBox(height: spacing),
            ],

            // 7) Hora de llegada
            if (!user.isCancelled && !user.isCollected && !hasProblem) ...[
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Llegada: '
                  '${etaStart.hour.toString().padLeft(2, '0')}:'
                  '${etaStart.minute.toString().padLeft(2, '0')}'' – '
                  '${etaEnd.hour.toString().padLeft(2, '0')}:'
                  '${etaEnd.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: isCompact ? 12 : 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
              ),
              SizedBox(height: spacing),
            ],

            // 8) Botones de cancelar/reanudar
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
                          '¿Seguro que quieres cancelar la recogida de hoy?',
                          () => userRouteProvider.cancelCurrentPickup(),
                          const LinearGradient(
                            colors: [
                              Color(0xFFB71C1C),
                              Color(0xFFE53935),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      icon: const Icon(Icons.cancel, color: Colors.white, semanticLabel: 'Icono cancelar'),
                      label: const Text('Cancelar Recogida', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        textStyle: TextStyle(fontSize: isCompact ? 12 : 14),
                      ),
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: user.isCancelled
                          ? () => _showConfirmation(
                                context,
                                'Reanudar Recogida',
                                '¿Quieres reanudar la recogida de hoy?',
                                () => userRouteProvider.removeCancelCurrentPickup(),
                                const LinearGradient(
                                  colors: [Color(0xFF2E7D32), Color(0xFF66BB6A),],          
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              )
                          : null,
                      icon: const Icon(Icons.undo, color: Colors.white, semanticLabel: 'Icono reanudar'),
                      label: const Text('Reanudar Recogida', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, textStyle: TextStyle(fontSize: isCompact ? 12 : 14),
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
  LinearGradient confirmGradient,
) async {
  final bool? resultado = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),


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

      // CONTENIDO
      content: Text(
        content,
        style: const TextStyle(fontSize: 16),
      ),

      // ACCIONES
      actionsPadding: EdgeInsets.zero,
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
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
                  gradient: confirmGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
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

  if (resultado == true) {
    onConfirm();
  }
}
