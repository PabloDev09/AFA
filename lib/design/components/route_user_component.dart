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

    // -------- Widget para usuario PENDIENTE (no está siendo recogido) --------
  Widget _buildPendingUserCard(
    BuildContext context,
    RouteUser user,
    bool isCompact,
  ) {
    final hours = user.distanceInMinutes ~/ 60;
    final mins = user.distanceInMinutes % 60;
    final formatted = [
      if (hours > 0) '${hours}h',
      '${mins}min',
    ].join(' ');

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isCompact ? 6 : 10),
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              spreadRadius: 2,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón Llamar (misma fila que antes, sin cambios)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${user.name} ${user.surnames}',
                    style: TextStyle(
                      fontSize: isCompact ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isCompact ? 8 : 16),
                ElevatedButton.icon(
                  onPressed: () => _callNumber(user.phoneNumber),
                  icon: Icon(Icons.call, size: isCompact ? 16 : 24),
                  label: Text(
                    'Llamar',
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 8 : 12,
                      horizontal: isCompact ? 8 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            Divider(
              color: Colors.grey,
              height: isCompact ? 16 : 24,
            ),
            _buildUserInfoRow(
              Icons.bus_alert,
              'Parada',
              'Nº ${user.numPick}',
              isCompact,
              Colors.cyan.shade800,
            ),
            _buildUserInfoRow(
              Icons.location_on,
              'Dirección',
              Utils().formatAddress(user.address),
              isCompact,
              Colors.blue,
            ),
            _buildUserInfoRow(
              Icons.access_time,
              'Tiempo estimado',
              user.distanceInMinutes == 0 ? 'No disponible' : formatted,
              isCompact,
              user.distanceInMinutes == 0 ? Colors.redAccent : Colors.blue,
            ),
            _buildUserInfoRow(
              Icons.social_distance,
              'Distancia estimada',
              user.distanceInKm == 0 ? 'No disponible' : '${user.distanceInKm} km',
              isCompact,
              user.distanceInMinutes == 0 ? Colors.redAccent : Colors.blue,
            ),

            SizedBox(height: isCompact ? 12 : 20),

            // Botones de acción para usuario pendiente
            _buildActionButtons(
              context,
              user,
              false, // isBeingPicked = false
              isCompact,
            ),
          ],
        ),
      ),
    );
  }

  // -------- Widget para usuario RECOGIÉNDOSE (está siendo recogido) --------
  Widget _buildPickedUserCard(
    BuildContext context,
    RouteUser user,
    bool isCompact,
  ) {
    final hours = user.distanceInMinutes ~/ 60;
    final mins = user.distanceInMinutes % 60;

    // Determinamos color de progreso en función del tiempo
    Color fillColor;
    if (user.distanceInMinutes <= 5) {
      fillColor = Colors.green;
    } else if (user.distanceInMinutes <= 10) {
      fillColor = Colors.orange;
    } else {
      fillColor = Colors.red;
    }

    final now = DateTime.now();
    final eta = now.add(Duration(minutes: user.distanceInMinutes));
    final etaEnd = eta.add(const Duration(minutes: 5));
    String fmtH(DateTime t) =>
        '${t.hour.toString().padLeft(2, "0")}:${t.minute.toString().padLeft(2, "0")}';

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isCompact ? 6 : 10),
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.green.shade200,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              spreadRadius: 2,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre y botón Llamar (seguirá apareciendo debajo del bloque “Ruta/Parada”)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${user.name} ${user.surnames}',
                    style: TextStyle(
                      fontSize: isCompact ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isCompact ? 8 : 16),
                ElevatedButton.icon(
                  onPressed: () => _callNumber(user.phoneNumber),
                  icon: Icon(Icons.call, size: isCompact ? 16 : 24),
                  label: Text(
                    'Llamar',
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isCompact ? 8 : 12,
                      horizontal: isCompact ? 8 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 12 : 16),
            Divider(
              color: Colors.white,
              height: isCompact ? 16 : 24,
            ),
            _buildUserInfoRow(
              Icons.bus_alert,
              'Parada',
              'Nº ${user.numPick}',
              isCompact,
              Colors.cyan.shade800,
            ),
            SizedBox(height: isCompact ? 8 : 12),
            _buildUserInfoRow(
              Icons.location_on,
              'Dirección',
              Utils().formatAddress(user.address),
              isCompact,
              Colors.blue,
            ),
            SizedBox(height: isCompact ? 8 : 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                final progress = ((15 - user.distanceInMinutes) / 15).clamp(0.0, 1.0);
                final busWidth = isCompact ? 30.0 : 50.0;
                final left = progress * (barWidth - busWidth);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user.distanceInKm != 0.0) ...[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: barWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Tooltip(
                                    message: 'Tiempo estimado',
                                    child: Icon(
                                      Icons.access_time,
                                      color: Colors.blue,
                                      size: isCompact ? 20 : 28,
                                    ),
                                  ),
                                  SizedBox(width: isCompact ? 8 : 12),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        if (hours > 0)
                                          TextSpan(
                                            text: '${hours}h ',
                                            style: TextStyle(
                                              fontSize: isCompact ? 14 : 16,
                                              fontWeight: FontWeight.bold,
                                              color: fillColor,
                                            ),
                                          ),
                                        TextSpan(
                                          text: '${mins}min',
                                          style: TextStyle(
                                            fontSize: isCompact ? 14 : 16,
                                            fontWeight: FontWeight.bold,
                                            color: fillColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isCompact ? 4 : 6),
                              SizedBox(
                                height: busWidth + (isCompact ? 4 : 8),
                                width: barWidth,
                                child: Stack(
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
                                ),
                              ),
                              SizedBox(height: isCompact ? 2 : 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Llegada: ${fmtH(eta)} – ${fmtH(etaEnd)}',
                                    style: TextStyle(
                                      fontSize: isCompact ? 10 : 12,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Cuando no hay distancia ni tiempo disponible
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildUserInfoRow(
                                    Icons.access_time,
                                    'Tiempo estimado',
                                    'No disponible',
                                    isCompact,
                                    Colors.redAccent,
                                  ),
                                  SizedBox(height: isCompact ? 8 : 12),
                                  _buildUserInfoRow(
                                    Icons.social_distance,
                                    'Distancia estimada',
                                    'No disponible',
                                    isCompact,
                                    Colors.redAccent,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    SizedBox(height: isCompact ? 8 : 12),

                    // Mapa con color de ruta
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: double.infinity,
                        child: MapComponent(
                          isDriver: true,
                          routeColor: fillColor,
                        ),
                      ),
                    ),

                    SizedBox(height: isCompact ? 12 : 20),
                  ],
                );
              },
            ),

            // Botones de acción para usuario en camino
            _buildActionButtons(
              context,
              user,
              true, // isBeingPicked = true
              isCompact,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildUserInfoRow(
    IconData icon,
    String label,
    String value,
    bool isCompact,
    Color iconColor
  ) {
    const textStyleValue = TextStyle(
      color: Colors.black54,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: label,
            child: Icon(icon, size: isCompact ? 20 : 28, color: iconColor),
          ),
          SizedBox(width: isCompact ? 8 : 12),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  value,
                  style: textStyleValue,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
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
