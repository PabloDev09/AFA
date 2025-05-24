import 'dart:async';
import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
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
  Color confirmColor,
) {
  showDialog<bool>(
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
                    fontSize: 18,
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    },
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
      final routeUsers = driverRouteProvider.pendingUsers;
      final bool isSomeoneBeingPicked = routeUsers.any((user) => user.isBeingPicking);
      final hasProblem = driverRouteProvider.routeDriver.hasProblem;

      routeUsers.sort((a, b) => a.numPick.compareTo(b.numPick));
    
      

      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: (hasProblem ? Colors.green : Colors.red).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasProblem ? Colors.green : Colors.red,
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (hasProblem) {
                  driverRouteProvider.clearRouteHasProblem();
                } else {
                  driverRouteProvider.markRouteHasProblem();
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasProblem ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: hasProblem ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasProblem ? 'Marcar incidencia como resuelta' : 'Reportar incidencia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: hasProblem ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
          // Nuevo header con tarjetas de estado
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  label: 'Por recoger',
                  count: driverRouteProvider.pendingUsers.length,
                  color: Colors.blueAccent,
                  isCompact: isCompact,
                ),
              ),
              SizedBox(width: isCompact ? 8 : 16),
              Expanded(
                child: _buildStatusCard(
                  label: 'Recogidos',
                  count: driverRouteProvider.collectedUsers.length,
                  color: Colors.green,
                  isCompact: isCompact,
                ),
              ),
              SizedBox(width: isCompact ? 8 : 16),
              Expanded(
                child: _buildStatusCard(
                  label: 'Cancelados',
                  count: driverRouteProvider.cancelledUsers.length,
                  color: Colors.redAccent,
                  isCompact: isCompact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (routeUsers.isNotEmpty)
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: (
                // si hay alguien en recogida, filtra solo ese usuario
                routeUsers.any((u) => u.isBeingPicking)
                    ? routeUsers.where((u) => u.isBeingPicking).toList()
                    : routeUsers
              ).map((user) =>
                  SizedBox(
                    width: MediaQuery.of(context).size.width < 600
                        ? MediaQuery.of(context).size.width * 0.95
                        : 400,
                    child: _AnimatedUserCard(
                      child: _buildUserCard(context, user, isSomeoneBeingPicked, isCompact),
                    ),
                  )
              ).toList(),
            )
          else
            _buildNoUsers(context),
          const SizedBox(height: 20),
        ],
      );
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


Widget _buildUserCard(BuildContext context, RouteUser user, bool isSomeoneBeingPicked, bool isCompact) {
  final width = MediaQuery.of(context).size.width;
  final cardWidth = isCompact ? width * 0.95 : 400;
  final hours = user.distanceInMinutes ~/ 60;
  final mins  = user.distanceInMinutes % 60;
  final formatted = [
    if (hours > 0) '${hours}h',
    '${mins}min'
  ].join(' ');

  return Center(
    child: SizedBox(
      width: cardWidth.toDouble(),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isCompact ? 6 : 10),
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: user.isBeingPicking ? Colors.green.shade200 : Colors.white,
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
            // Nombre y botón Llamar
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            Divider(color: user.isBeingPicking ? Colors.white : Colors.grey,  height: isCompact ? 16 : 24),

            // Info usuario y dirección
            _buildUserInfoRow(Icons.person, 'Usuario:', user.username, isCompact),
            _buildUserInfoRow(Icons.location_on, 'Dirección:', user.address, isCompact),

            // Tiempos y distancias
            if (!user.isBeingPicking) ...[
              user.distanceInMinutes == 0
                  ? _buildUserInfoRow(Icons.access_time, 'Tiempo estimado:', 'No disponible', isCompact)
                  : _buildUserInfoRow(Icons.access_time, 'Tiempo estimado:', formatted, isCompact),
            ],
            user.distanceInKm == 0
                ? _buildUserInfoRow(Icons.social_distance, 'Distancia estimada:', 'No disponible', isCompact)
                : _buildUserInfoRow(Icons.social_distance, 'Distancia estimada:', '${user.distanceInKm} km', isCompact),

            // Barra de progreso para el usuario en recogida
          if (user.isBeingPicking) ...[
            SizedBox(height: isCompact ? 8 : 12),

            LayoutBuilder(builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final progress = ((15 - user.distanceInMinutes) / 15).clamp(0.0, 1.0);
              final busWidth = isCompact ? 30.0 : 50.0;
              final left = progress * (barWidth - busWidth);

              // color según distancia
              Color fillColor;
              if (user.distanceInMinutes <= 5) {
                fillColor = Colors.green;
              } else if (user.distanceInMinutes <= 10) {
                fillColor = Colors.orange;
              } else {
                fillColor = Colors.red;
              }

              // calcula ETA y rango +5min
              final now = DateTime.now();
              final eta = now.add(Duration(minutes: user.distanceInMinutes));
              final etaEnd = eta.add(const Duration(minutes: 5));
              String fmtH(DateTime t) =>
                  '${t.hour.toString().padLeft(2,"0")}:${t.minute.toString().padLeft(2,"0")}';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primera línea: icono + tiempo estimado en grande
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.black87, size: isCompact ? 18 : 22),
                      const SizedBox(width: 6),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: 'Tiempo Estimado: ',
                            style: TextStyle(
                              fontSize: isCompact ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (hours > 0) ...[
                            TextSpan(
                              text: '${hours}h ',
                              style: TextStyle(
                                fontSize: isCompact ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: fillColor,
                              ),
                            ),
                          ],
                          TextSpan(
                            text: '${mins}min',
                            style: TextStyle(
                              fontSize: isCompact ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: fillColor,
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
              
                  SizedBox(height: isCompact ? 8 : 12),
              
                  // Barra de progreso +
                  SizedBox(
                    height: busWidth + (isCompact ? 4 : 8),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // fondo gris
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
                        // avance coloreado
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
                        // autobús animado
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
              
                  // Hora de llegada estimada en pequeño badge
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Llegada: ${fmtH(eta)} – ${fmtH(etaEnd)}',
                      style: TextStyle(
                        fontSize: isCompact ? 10 : 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              
                  SizedBox(height: isCompact ? 12 : 20),
                ],
              );
            }),
          ],

            // Botones de acción
            _buildActionButtons(context, user, isSomeoneBeingPicked, isCompact),
          ],
        ),
      ),
    ),
  );
}



Widget _buildUserInfoRow(IconData icon, String label, String value, bool isCompact) {
  final textStyleLabel = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    fontSize: isCompact ? 14 : 20,
  );
  final textStyleValue = TextStyle(
    color: Colors.black54,
    fontSize: label.startsWith('Dirección') 
        ? (isCompact ? 12 : 15) 
        : (isCompact ? 12 : 18),
  );

  return Padding(
    padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: isCompact ? 20 : 28, color: Colors.blue),
        SizedBox(width: isCompact ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textStyleLabel),
              SizedBox(height: isCompact ? 2 : 4),
              Text(
                value,
                style: textStyleValue,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


Widget _buildActionButtons(
  BuildContext context,
  RouteUser user,
  bool isSomeoneBeingPicked,
  bool isCompact,
) {
  final iconSize = isCompact ? 16.0 : 24.0;
  final fontSize = isCompact ? 12.0 : 16.0;
  final verticalPadding = isCompact ? 8.0 : 16.0;
  final spacerWidth = isCompact ? 4.0 : 8.0;

  return Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: isSomeoneBeingPicked || user.isBeingPicking ? null : () {
            _showConfirmationDialog(
              context,
              'Recoger Usuario',
              '¿Está seguro de que desea recoger a ${user.name}?',
              () => Provider.of<DriverRouteProvider>(context, listen: false)
                        .pickUpUser(user.username, user.numPick),
              Colors.blue,
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
      Expanded(
        child: ElevatedButton.icon(
          onPressed: !user.isBeingPicking ? null : () {
            _showConfirmationDialog(
              context,
              'Marcar como Recogido',
              '¿Ha recogido ya a ${user.name}?',
              () => Provider.of<DriverRouteProvider>(context, listen: false)
                        .markUserAsCollected(user.username),
              Colors.green,
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
      Expanded(
        child: ElevatedButton.icon(
          onPressed: !user.isBeingPicking ? null : () {
            _showConfirmationDialog(
              context,
              'Cancelar Recogida',
              '¿Desea cancelar la recogida de ${user.name}?',
              () => Provider.of<DriverRouteProvider>(context, listen: false)
                        .cancelPickUpUser(user.username),
              Colors.red,
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
  );
}

  Widget _buildStatusCard({
    required String label,
    required int count,
    required Color color,
    required bool isCompact,
  }) {
    return Container(
      // ancho eliminado para que lo defina el Expanded
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 8 : 12,
        horizontal: isCompact ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: isCompact ? 14 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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