import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RouteUserComponent extends StatelessWidget {
  const RouteUserComponent({super.key});

  void _showConfirmationDialog(
      BuildContext context, String title, String content, VoidCallback onConfirm, Color confirmColor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
              child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverRouteProvider>(
      builder: (context, driverRouteProvider, _) {
        final routeUsers = driverRouteProvider.usersToPickUp;
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
          Text(
            '${user.name} ${user.surnames}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Divider(),
          _buildUserInfoRow(Icons.person, 'Usuario:', user.username),
          _buildUserInfoRow(Icons.phone, 'Teléfono:', user.phoneNumber),
          _buildUserInfoRow(Icons.location_on, 'Dirección:', user.address),
          const SizedBox(height: 20),
          _buildActionButtons(context, user, isSomeoneBeingPicked),
        ],
      ),
    );
  }

  Widget _buildUserInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54, fontSize: 20),
              overflow: TextOverflow.ellipsis,
            ),
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
                () => Provider.of<DriverRouteProvider>(context, listen: false).collectedUser(user.username),
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
