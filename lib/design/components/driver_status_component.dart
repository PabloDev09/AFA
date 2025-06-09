import 'dart:async';
import 'package:afa/design/components/map_component.dart';
import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Muestra el estado del conductor con:
/// - Mensaje de estado general (cancelado, recogido, incidencia, ocupado, en camino).
/// - Si está en camino hacia el usuario, muestra el MapComponent con el GIF y barra de progreso.
/// - Si no está en camino, muestra solo la información sin mapa.
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
          if (routeProvider.hasProblem)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: isCompact ? 8 : 12,
              ),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.redAccent,
                    width: 2,
                  ),
                  color: const Color.fromARGB(54, 255, 0, 25),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: isCompact ? 28 : 36,
                    ),
                    SizedBox(width: isCompact ? 8 : 12),
                    Expanded(
                      child: Text(
                        'Se ha reportado una incidencia en la ruta. Hasta que no se indique como resuelta no se podrá continuar la ruta.',
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

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
                  ? _buildStatusCard(context, routeProvider, isCompact)
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
        ],
      );
    },
  );
}


Widget _buildStatusCard(
  BuildContext context,
  UserRouteProvider userRouteProvider,
  bool isCompact,
) {
  final user = userRouteProvider.routeUser;
  final driver = userRouteProvider.routeDriver;
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
    } else if (stopsRemaining == 2 || stopsRemaining == 0) {
      pickOrderMessage = 'Eres el siguiente en ser recogido';
    } else if (stopsRemaining > 2) {
      pickOrderMessage = 'Quedan $stopsRemaining paradas antes de ti';
    }
  }

  final mins = user.distanceInMinutes;
  final hours = mins ~/ 60;

  final now = DateTime.now();
  final etaStart = now.add(Duration(minutes: mins));
  final etaEnd = etaStart.add(const Duration(minutes: 5));

  // TextStyle para etiquetas
  final TextStyle labelStyle = TextStyle(
    fontSize: isCompact ? 14 : 16,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  // Variables de estilo adaptativo
  final double horizontalPadding = isCompact ? 12 : 20;
  final double verticalPadding = isCompact ? 10 : 16;
  final double spacing = isCompact ? 8 : 12;
  final double avatarRadius = isCompact ? 16 : 20;

  // TextStyles para mantener coherencia con otros cards
  final TextStyle nameStyle = TextStyle(
    fontSize: isCompact ? 14 : 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );
  final TextStyle titleStyle = TextStyle(
    fontSize: isCompact ? 14 : 16,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  final TextStyle bodyStyle = TextStyle(
    fontSize: isCompact ? 12 : 14,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
  );

  // Valores por defecto para estado "ocupado"
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
    fillColor = Colors.redAccent;
  } else if (user.isCollected) {
    borderColor = Colors.green;
    title = 'Recogida completada';
    message = 'Has sido recogido.';
    icon = Icons.check_circle;
    fillColor = Colors.green;
  } else if (user.isBeingPicking) {
    borderColor = Colors.blueAccent;
    title = 'Conductor en camino';
    message = 'El conductor va hacia ti.';
    icon = Icons.directions_bus;
    fillColor = user.distanceInMinutes <= 5
        ? Colors.green.shade700
        : user.distanceInMinutes <= 10
            ? Colors.orange.shade700
            : Colors.red.shade700;
  } else if (isOtherBeingPicked) {
    borderColor = Colors.orangeAccent;
    title = 'Conductor ocupado';
    message = 'Está recogiendo a otro usuario.';
    icon = Icons.access_time_filled;
    fillColor = Colors.orangeAccent;
  }

  return _AnimatedUserCard(
    child: Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing,
        vertical: spacing / 2,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Información del conductor + botón llamar (si aún no se ha completado)
          if (!user.isCollected) ...[
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  radius: avatarRadius,
                  child: const Icon(
                    Icons.person,
                    color: Colors.blue,
                    semanticLabel: 'Icono conductor',
                  ),
                ),
                SizedBox(width: spacing / 2),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${driver.name} ${driver.surnames}',
                          style: nameStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              size: nameStyle.fontSize != null
                                  ? nameStyle.fontSize! * 0.7
                                  : 12,
                              color: Colors.green.shade300,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Conductor verificado',
                              style: TextStyle(
                                fontSize: nameStyle.fontSize != null
                                    ? nameStyle.fontSize! * 0.7
                                    : 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade300,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                          const SnackBar(
                            content: Text('No se pudo iniciar la llamada'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 12 : 16),
            Divider(color: Colors.grey.shade300, thickness: 1),
          ],

          // Nuevo contenedor para pickOrderMessage
          if (pickOrderMessage.isNotEmpty) ...[
            SizedBox(height: isCompact ? 8 : 12),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 14,
                vertical: isCompact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flag,
                    size: isCompact ? 16 : 20,
                    color: Colors.amber.shade700,
                  ),
                  SizedBox(width: spacing / 2),
                  Expanded(
                    child: Text(
                      pickOrderMessage,
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],


          SizedBox(height: isCompact ? 12 : 16),

          // Banner de estado (sin modificar color ni tipografía)
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: isCompact ? 6 : 10,
              ),
              decoration: BoxDecoration(
                color: borderColor, // mantenemos el color dinámico
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: isCompact ? 20 : 30, color: Colors.white),
                      SizedBox(width: spacing),
                      Text(
                        title,
                        style: titleStyle.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: isCompact ? 4 : 8),
                  Text(
                    message,
                    style: bodyStyle.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isCompact ? 16 : 20),

          // Sección de tiempo, distancia, barra de progreso y llegada (solo si se está recogiendo)
          if (user.isBeingPicking && user.distanceInKm != 0.0) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;
                final content = [
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: isCompact ? 18 : 22, color: Colors.blue),
                      SizedBox(width: isCompact ? 6 : 8),
                      Text('Tiempo estimado:', style: labelStyle),
                      SizedBox(width: isCompact ? 6 : 10),
                      Text(
                        (hours > 0) ? '${hours}h ${mins}m' : '${mins}m',
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: fillColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.map,
                          size: isCompact ? 18 : 22, color: Colors.blue),
                      SizedBox(width: isCompact ? 6 : 8),
                      Text('Distancia:', style: labelStyle),
                      SizedBox(width: isCompact ? 6 : 10),
                      Text(
                        '${user.distanceInKm.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: fillColor,
                        ),
                      ),
                    ],
                  ),
                ];
                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          content[0],
                          SizedBox(
                              height: isCompact ? 16 : 20), // espacio entre filas
                          content[1],
                        ],
                      )
                    : Row(
                        children: [
                          ...content[0].children,
                          const Spacer(),
                          ...content[1].children,
                        ],
                      );
              },
            ),
            SizedBox(height: isCompact ? 12 : 16),

            // Barra de progreso con ícono de bus
            LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                final progress = ((15 - user.distanceInMinutes) / 15)
                    .clamp(0.0, 1.0);
                final busSize = isCompact ? 28.0 : 48.0;
                final left = progress * (barWidth - busSize);

                return SizedBox(
                  height: busSize + (isCompact ? 4 : 8),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: busSize / 2 - (isCompact ? 3 : 5),
                        child: Container(
                          height: isCompact ? 6 : 10,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        width: progress * barWidth,
                        top: busSize / 2 - (isCompact ? 3 : 5),
                        child: Container(
                          height: isCompact ? 6 : 10,
                          decoration: BoxDecoration(
                            color: fillColor.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Positioned(
                        left: left,
                        top: 0,
                        child: Icon(
                          Icons.directions_bus,
                          size: busSize * 0.6,
                          color: fillColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: isCompact ? 12 : 16),

            // Hora estimada de llegada
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule,
                      size: isCompact ? 16 : 18, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
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
                ],
              ),
            ),
            SizedBox(height: isCompact ? 16 : 20),
          ],

          if (user.isBeingPicking) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: double.infinity,
                height: isCompact ? 120 : 180,
                child: MapComponent(
                  isDriver: false,
                  routeColor: fillColor,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],

          if (!user.isCollected) ...[
            _buildActionButtons(
              context,
              userRouteProvider,
              isCompact,
              fillColor,
            ),
          ],
        ],
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                    overlayColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.hovered)) {
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

 Widget _buildActionButtons(BuildContext context, UserRouteProvider userRouteProvider, bool isCompact, Color fillColor) {
    final iconSize = isCompact ? 16.0 : 24.0;
    final fontSize = isCompact ? 12.0 : 16.0;
    final verticalPadding = isCompact ? 8.0 : 16.0;
    final spacerWidth = isCompact ? 4.0 : 8.0;

      return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min, // Ocupa solo el ancho necesario
        children: [
          // Botón “Cancelar Recogida”
          SizedBox(
            width: MediaQuery.of(context).size.width / 2 - spacerWidth,
            child: ElevatedButton.icon(
              onPressed: userRouteProvider.routeUser.isCancelled
                  ? null
                  : () {
                      _showConfirmation(
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
                      );
                    },
              icon: Icon(
                Icons.cancel,
                color: Colors.white,
                size: iconSize,
                semanticLabel: 'Icono cancelar',
              ),
              label: Text(
                'Cancelar Recogida',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          SizedBox(width: spacerWidth),

          // Botón “Reanudar Recogida”
          SizedBox(
            width: MediaQuery.of(context).size.width / 2 - spacerWidth,
            child: ElevatedButton.icon(
              onPressed: userRouteProvider.routeUser.isCancelled
                  ? () {
                      _showConfirmation(
                        context,
                        'Reanudar Recogida',
                        '¿Quieres reanudar la recogida de hoy?',
                        () => userRouteProvider.removeCancelCurrentPickup(),
                        const LinearGradient(
                          colors: [
                            Color(0xFF2E7D32),
                            Color(0xFF66BB6A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      );
                    }
                  : null,
              icon: Icon(
                Icons.undo,
                color: Colors.white,
                size: iconSize,
                semanticLabel: 'Icono reanudar',
              ),
              label: Text(
                'Reanudar Recogida',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: verticalPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
}

class _AnimatedUserCard extends StatefulWidget {
  final Widget child;

  const _AnimatedUserCard({required this.child});

  @override
  State<_AnimatedUserCard> createState() => _AnimatedUserCardState();
}

class _AnimatedUserCardState extends State<_AnimatedUserCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.2),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}