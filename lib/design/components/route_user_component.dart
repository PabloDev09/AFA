import 'dart:async';
import 'package:afa/design/components/map_component.dart';
import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:afa/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class RouteUserComponent extends StatelessWidget {
  const RouteUserComponent({super.key});

  void _showConfirmationDialog(
  BuildContext context,
  String title,
  String content,
  VoidCallback onConfirm,
) {
  // Determinar el gradiente según el título
  List<Color> gradientColors;
  switch (title) {
    case 'Recoger Usuario':
      gradientColors = [const Color(0xFF063970), const Color(0xFF2196F3)];
      break;
    case 'Marcar como Recogido':
      gradientColors = [const Color(0xFF2E7D32), const Color(0xFF66BB6A)];
      break;
    case 'Cancelar Recogida':
      gradientColors = [const Color(0xFFB71C1C), const Color(0xFFE53935)];
      break;
    default:
      gradientColors = [const Color(0xFF063970), const Color(0xFF2196F3)];
  }

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      content: Text(content),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
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
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith(
                      (states) {
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.white.withOpacity(0.2);
                        }
                        return null;
                      },
                    ),
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
}


  Future<void> _callNumber(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('No se pudo lanzar el marcador: $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width <= 500;

    return Consumer<DriverRouteProvider>(
      builder: (context, driverRouteProvider, _) {
        // Si hay incidencia reportada, mostramos un contenedor de advertencia
        if (driverRouteProvider.routeDriver.hasProblem) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 8 : 12,
            ),
            child: _AnimatedUserCard(
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
            ) 
          );
        }

        final routeUsers = driverRouteProvider.pendingUsers;
        // Verificamos si hay algún usuario siendo recogido
        final bool isSomeoneBeingPicked = routeUsers.any((u) => u.isBeingPicking);

        // Ordenamos todos los usuarios por su número de pick
        routeUsers.sort((a, b) => a.numPick.compareTo(b.numPick));

        // Extraemos el usuario que está siendo recogido, si existe
        RouteUser? pickedUser;
        if (isSomeoneBeingPicked) {
          pickedUser = routeUsers.firstWhere((u) => u.isBeingPicking);
        }

        if (pickedUser != null) {
          // Si hay un usuario siendo recogido, mostramos solo ese widget
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AnimatedUserCard(
                child: _buildPickedUserCard(context, pickedUser, isCompact),
              ),
            ],
          );
        }

        if (routeUsers.isNotEmpty) {
          // Si no hay usuario siendo recogido, mostramos todos los pendientes
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: routeUsers.map((user) {
              return SizedBox(
                width: double.infinity,
                child: _AnimatedUserCard(
                  child: _buildPendingUserCard(context, user, isCompact),
                ),
              );
            }).toList(),
          );
        }

        // Si no hay ningún usuario en ruta
        return _buildNoUsers(context);
      },
    );
  }

  Widget _buildNoUsers(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car, size: 120, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'No hay usuarios en ruta',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
    );
  }

Widget _buildPendingUserCard(
  BuildContext context,
  RouteUser user,
  bool isCompact,
) {
  final hours = user.distanceInMinutes ~/ 60;
  final mins = user.distanceInMinutes % 60;
  [
    if (hours > 0) '${hours}h',
    '${mins}min',
  ].join(' ');

  final double horizontalPadding = isCompact ? 12 : 20;
  final double verticalPadding = isCompact ? 10 : 16;

  final TextStyle nameStyle = TextStyle(
    fontSize: isCompact ? 18 : 22,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );
  final TextStyle labelStyle = TextStyle(
    fontSize: isCompact ? 14 : 16,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  final TextStyle valueStyle = TextStyle(
    fontSize: isCompact ? 14 : 16,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );
  final TextStyle badgeStyle = TextStyle(
    fontSize: isCompact ? 14 : 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  return Center(
    child: Container(
      margin: EdgeInsets.symmetric(
        vertical: isCompact ? 8 : 12,
        horizontal: isCompact ? 16 : 24,
      ),
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            spreadRadius: 2,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Encabezado: Nombre + Botón Llamar ---
          LayoutBuilder(
            builder: (context, constraints) {
              final callButton = Tooltip(
                message: 'Llamar al usuario',
                child: IconButton(
                  icon: Icon(
                    Icons.call,
                    size: isCompact ? 20 : 24,
                    color: Colors.green,
                  ),
                  onPressed: () async {
                    await _callNumber(user.phoneNumber);
                  },
                ),
              );

               return Row(
                  children: [
                    CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    radius: 16,
                    child: const Icon(
                      Icons.person,
                      color: Colors.blue,
                      semanticLabel: 'Icono conductor',
                    ),
                  ),
                    SizedBox(width: isCompact ? 8 : 12),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.name} ${user.surnames}',
                              style: nameStyle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.security,
                                  size: nameStyle.fontSize != null ? nameStyle.fontSize! * 0.7 : 12,
                                  color: Colors.green.shade300,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Usuario verificado',
                                  style: TextStyle(
                                    fontSize: nameStyle.fontSize != null ? nameStyle.fontSize! * 0.7 : 12,
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
                    SizedBox(width: isCompact ? 8 : 16),
                    callButton,
                  ],
                );
            },
          ),

          SizedBox(height: isCompact ? 12 : 16),
          Divider(color: Colors.grey.shade300, thickness: 1),
          SizedBox(height: isCompact ? 12 : 16),

          // --- Badge circular “Parada” centrado ---
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: isCompact ? 6 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.cyan.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_pin_circle,
                      size: isCompact ? 18 : 22,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text('Parada ${user.numPick}', style: badgeStyle),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: isCompact ? 14 : 20),

          // --- Dirección ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                size: isCompact ? 18 : 22,
                color: Colors.blue.shade700,
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Text('Dirección:', style: labelStyle),
              SizedBox(width: isCompact ? 6 : 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Utils().formatAddress(user.address),
                    style: valueStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isCompact ? 16 : 20),

          if (user.distanceInKm != 0.0) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;
                final content = [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: isCompact ? 18 : 22, color: Colors.blue),
                      SizedBox(width: isCompact ? 6 : 8),
                      Text('Tiempo estimado:', style: labelStyle),
                      SizedBox(width: isCompact ? 6 : 10),
                      Text(
                        (hours > 0) ? '${hours}h ${mins}m' : '${mins}m',
                        style: valueStyle,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.map, size: isCompact ? 18 : 22, color: Colors.blue),
                      SizedBox(width: isCompact ? 6 : 8),
                      Text('Distancia:', style: labelStyle),
                      SizedBox(width: isCompact ? 6 : 10),
                      Text(
                        '${user.distanceInKm.toStringAsFixed(1)} km',
                        style: valueStyle,
                      ),
                    ],
                  ),
                ];

                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          content[0],
                          SizedBox(height: isCompact ? 16 : 20),
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
          ],

          SizedBox(height: isCompact ? 12 : 16),

          // --- Botones de acción ---
          _buildActionButtons(context, user, false, isCompact),
        ],
      ),
    ),
  );
}


Widget _buildPickedUserCard(
  BuildContext context,
  RouteUser user,
  bool isCompact,
) {
  final hours = user.distanceInMinutes ~/ 60;
  final mins = user.distanceInMinutes % 60;

  final Color fillColor = user.distanceInMinutes <= 5
      ? Colors.green.shade700
      : user.distanceInMinutes <= 10
          ? Colors.orange.shade700
          : Colors.red.shade700;

  final now = DateTime.now();
  final eta = now.add(Duration(minutes: user.distanceInMinutes));
  final etaEnd = eta.add(const Duration(minutes: 5));

  String fmtH(DateTime t) =>
      '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}';

  final double horizontalPadding = isCompact ? 12 : 20;
  final double verticalPadding = isCompact ? 10 : 16;

  final TextStyle nameStyle = TextStyle(
    fontSize: isCompact ? 18 : 22,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );
  final TextStyle labelStyle = TextStyle(
    fontSize: isCompact ? 14 : 16,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  final TextStyle valueStyle = TextStyle(
    fontSize: isCompact ? 14 : 16,
    fontWeight: FontWeight.w400,
    color: Colors.black54,
  );
  final TextStyle badgeStyle = TextStyle(
    fontSize: isCompact ? 14 : 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  return Center(
    child: Container(
      margin: EdgeInsets.symmetric(
        vertical: isCompact ? 8 : 12,
        horizontal: isCompact ? 16 : 24,
      ),
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            spreadRadius: 2,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        LayoutBuilder(
            builder: (context, constraints) {
              final callButton = Tooltip(
                message: 'Llamar al usuario',
                child: IconButton(
                  icon: Icon(
                    Icons.call,
                    size: isCompact ? 20 : 24,
                    color: Colors.green,
                  ),
                  onPressed: () async {
                    await _callNumber(user.phoneNumber);
                  },
                ),
              );

              return Row(
                children: [
                  CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  radius: 16,
                  child: const Icon(
                    Icons.person,
                    color: Colors.blue,
                    semanticLabel: 'Icono conductor',
                  ),
                ),
                  SizedBox(width: isCompact ? 8 : 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.name} ${user.surnames}',
                            style: nameStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                size: nameStyle.fontSize != null ? nameStyle.fontSize! * 0.7 : 12,
                                color: Colors.green.shade300,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Usuario verificado',
                                style: TextStyle(
                                  fontSize: nameStyle.fontSize != null ? nameStyle.fontSize! * 0.7 : 12,
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
                  SizedBox(width: isCompact ? 8 : 16),
                  callButton,
                ],
              );
            },
          ),

          SizedBox(height: isCompact ? 12 : 16),
          Divider(color: Colors.grey.shade300, thickness: 1),
          SizedBox(height: isCompact ? 12 : 16),

          // Badge parada
         Align(
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 6 : 10,
            ),
            decoration: BoxDecoration(
              color: Colors.cyan.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // 👈 ¡Esto es clave!
              children: [
                Icon(Icons.person_pin_circle, size: isCompact ? 18 : 22, color: Colors.white),
                const SizedBox(width: 4),
                Text('Parada ${user.numPick}', style: badgeStyle),
              ],
            ),
          ),
        ),

          SizedBox(height: isCompact ? 14 : 20),

          // Dirección
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: isCompact ? 18 : 22, color: Colors.blue),
              SizedBox(width: isCompact ? 6 : 8),
              Text('Dirección:', style: labelStyle),
              SizedBox(width: isCompact ? 6 : 10),
              Expanded(
                child: Text(
                  Utils().formatAddress(user.address),
                  style: valueStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 16 : 20),

          // Tiempo y distancia o mensaje de no disponible
          if (user.distanceInKm != 0.0) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;
                final content = [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: isCompact ? 18 : 22, color: Colors.blue),
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
                      Icon(Icons.map, size: isCompact ? 18 : 22, color: Colors.blue),
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
                      SizedBox(height: isCompact ? 16 : 20),  // <-- espacio entre las filas
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
                final progress = ((15 - user.distanceInMinutes) / 15).clamp(0.0, 1.0);
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
                  Icon(Icons.schedule, size: isCompact ? 16 : 18, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    'Llegada: ${fmtH(eta)} – ${fmtH(etaEnd)}',
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
          ] else ...[
            Text(
              'Tiempo estimado: No disponible',
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade400,
              ),
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Text(
              'Distancia: No disponible',
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade400,
              ),
            ),
            SizedBox(height: isCompact ? 16 : 20),
          ],

          // Mapa
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: isCompact ? 160 : 240,
              child: MapComponent(
                isDriver: true,
                routeColor: fillColor,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 16 : 24),

          // Botones de acción
          _buildActionButtons(context, user, true, isCompact),
        ],
      ),
    ),
  );
}




  Widget _buildActionButtons(
  BuildContext context,
  RouteUser user,
  bool isBeingPicked,
  bool isCompact,
) {
  final iconSize = isCompact ? 16.0 : 24.0;
  final fontSize = isCompact ? 12.0 : 16.0;
  final verticalPadding = isCompact ? 8.0 : 16.0;
  final spacerWidth = isCompact ? 4.0 : 8.0;

return FittedBox(
  fit: BoxFit.scaleDown,
  child: Row(
    mainAxisSize: MainAxisSize.min, // Que el Row ocupe solo lo necesario
    children: [
      SizedBox(
        width: MediaQuery.of(context).size.width / 3 - spacerWidth * 2,
        child: ElevatedButton.icon(
          onPressed: isBeingPicked
              ? null
              : () {
                  _showConfirmationDialog(
                    context,
                    'Recoger Usuario',
                    '¿Está seguro de que desea recoger a ${user.name}?',
                    () => Provider.of<DriverRouteProvider>(context, listen: false)
                        .pickUpUser(user.username, user.numPick),
                  );
                },
          icon: Icon(Icons.person_search_sharp, color: Colors.white, size: iconSize),
          label: Text(
            'Recoger',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: fontSize,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      SizedBox(width: spacerWidth),
      SizedBox(
        width: MediaQuery.of(context).size.width / 3 - spacerWidth * 2,
        child: ElevatedButton.icon(
          onPressed: !isBeingPicked
              ? null
              : () {
                  _showConfirmationDialog(
                    context,
                    'Marcar como Recogido',
                    '¿Ha recogido ya a ${user.name}?',
                    () => Provider.of<DriverRouteProvider>(context, listen: false)
                        .markUserAsCollected(user.username),
                  );
                },
          icon: Icon(Icons.check_circle, color: Colors.white, size: iconSize),
          label: Text(
            'Recogido',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: fontSize,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      SizedBox(width: spacerWidth),
      SizedBox(
        width: MediaQuery.of(context).size.width / 3 - spacerWidth * 2,
        child: ElevatedButton.icon(
          onPressed: !isBeingPicked
              ? null
              : () {
                  _showConfirmationDialog(
                    context,
                    'Cancelar Recogida',
                    '¿Desea cancelar la recogida de ${user.name}?',
                    () => Provider.of<DriverRouteProvider>(context, listen: false)
                        .cancelPickUpUser(user.username),
                  );
                },
          icon: Icon(Icons.cancel, color: Colors.white, size: iconSize),
          label: Text(
            'Cancelar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: fontSize,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(vertical: verticalPadding),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
