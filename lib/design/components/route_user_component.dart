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
    return Consumer<DriverRouteProvider>(
      builder: (context, driverRouteProvider, _) {
        final routeUsers = driverRouteProvider.pendingUsers;
        final bool isSomeoneBeingPicked = routeUsers.any((user) => user.isBeingPicking);
        final int usersLeft = routeUsers.where((user) => !user.isBeingPicking).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.route, color: Colors.white, size: 40),
                const SizedBox(width: 10),
                const Text(
                  'Usuarios por recoger',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$usersLeft',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (routeUsers.isNotEmpty)
              ...routeUsers.map((user) => _buildUserCard(context, user, isSomeoneBeingPicked))
            else
              _buildNoUsers(context),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildNoUsers(BuildContext context) {
    return const Center(
      child: Column(
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
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, RouteUser user, bool isSomeoneBeingPicked) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
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
          // Fila superior: nombre y botón verde 'Llamar' a la derecha
          Row(
            children: [
              Expanded(
                child: Text(
                  '${user.name} ${user.surnames}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _callNumber(user.phoneNumber),
                icon: const Icon(Icons.call),
                label: const Text('Llamar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const Divider(),
          _buildUserInfoRow(Icons.person, 'Usuario:', user.username),
          _buildUserInfoRow(Icons.location_on, 'Dirección:', user.address),
          const SizedBox(height: 20),
          _buildActionButtons(context, user, isSomeoneBeingPicked),
        ],
      ),
    );
  }

  Widget _buildUserInfoRow(IconData icon, String label, String value) {
    const textStyleLabel = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black87,
      fontSize: 20,
    );
    const textStyleValue = TextStyle(color: Colors.black54, fontSize: 20);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.blue),
          const SizedBox(width: 12),
          Text(label, style: textStyleLabel),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value, style: textStyleValue, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, RouteUser user, bool isSomeoneBeingPicked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!user.isBeingPicking)
          ElevatedButton(
            onPressed: isSomeoneBeingPicked
                ? null
                : () {
                    _showConfirmationDialog(
                      context,
                      'Recoger Usuario',
                      '¿Está seguro de que desea recoger a ${user.name}?',
                      () => Provider.of<DriverRouteProvider>(context, listen: false).pickUpUser(user.username),
                      Colors.blue,
                    );
                  },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Recoger Usuario', style: TextStyle(color: Colors.white)),
          ),
        if (user.isBeingPicking) ...[
          ElevatedButton(
            onPressed: () {
              _showConfirmationDialog(
                context,
                'Marcar como Recogido',
                '¿Está seguro de que ha recogido a ${user.name}?',
                () => Provider.of<DriverRouteProvider>(context, listen: false).markUserAsCollected(user.username),
                Colors.green,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Marcar como Recogido', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              _showConfirmationDialog(
                context,
                'Cancelar Recogida',
                '¿Está seguro de que desea cancelar la recogida de ${user.name}?',
                () => Provider.of<DriverRouteProvider>(context, listen: false).cancelPickUpUser(user.username),
                Colors.red,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar Recogida', style: TextStyle(color: Colors.white)),
          ),
        ],
      ],
    );
  }
}
