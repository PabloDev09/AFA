import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/providers/user_active_provider.dart';
import 'package:afa/logic/providers/user_pending_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PendingUserComponent extends StatelessWidget {
  const PendingUserComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserPendingProvider>(
      builder: (context, userPendingProvider, _) {
        final pendingUsers = userPendingProvider.pendingUsers;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_alt_rounded, color: Colors.white, size: 30),
                SizedBox(width: 6),
                Text(
                  'Peticiones de registro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (pendingUsers.isEmpty)
              _buildNoUsersDirectly(context)
            else
              _buildPendingUsersCards(context, pendingUsers),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildNoUsersDirectly(BuildContext context) {
    double fontSize = MediaQuery.of(context).size.width * 0.02;
    fontSize = fontSize.clamp(14, 18);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono principal para peticiones pendientes con "X" pequeña en la esquina superior derecha
            const SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 30,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No hay peticiones de registro',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'En cuanto existan usuarios pendientes se mostrarán aquí.',
              style: TextStyle(
                fontSize: fontSize * 0.9,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUsersCards(BuildContext context, List<User> pendingUsers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        double fontSize = constraints.maxWidth * 0.02;
        fontSize = fontSize.clamp(22, 24);
        double columnFactor = constraints.maxWidth / 340;
        columns = columnFactor.floor();
        double decimalPart = columnFactor - columns;
        fontSize = (fontSize + decimalPart * 6).clamp(22, 25);
        const double spacing = 16;
        final double totalSpacing = spacing * (columns - 1);
        final double itemWidth = (constraints.maxWidth - totalSpacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: pendingUsers.map((user) {
            return SizedBox(
              width: itemWidth,
              height: 350,
              child: _buildUserContainer(context, user, fontSize),
            );
          }).toList(),
        );
      },
    );
  }

  /// Contenedor interno. Va dentro de un SizedBox.
  Widget _buildUserContainer(BuildContext context, User user, double fontSize) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _buildUserContent(context, user, fontSize),
        ),
      ),
    );
  }

  Widget _buildUserContent(BuildContext context, User user, double fontSize) {
    Map<IconData, Color> iconColors = {
      Icons.person: Colors.blue.shade300,
      Icons.email: Colors.green.shade300,
      Icons.phone: Colors.orange.shade300,
      Icons.location_on: Colors.red.shade300,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Se elimina el botón de "más opciones"
                Text(
                  '${user.name} ${user.surnames}',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Datos personales',
                  style: TextStyle(
                    fontSize: fontSize * 0.9,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Divider(),
                _buildUserInfoRow(Icons.person, 'Usuario:', user.username, fontSize, iconColors),
                _buildUserInfoRow(Icons.email, 'Email:', user.mail, fontSize, iconColors),
                _buildUserInfoRow(Icons.phone, 'Teléfono:', user.phoneNumber, fontSize, iconColors),
                _buildUserInfoRow(Icons.location_on, 'Dirección:', user.address, fontSize, iconColors),
              ],
            ),
          ),
        ),
        // Botones de acción pegados abajo
        _buildActionButtons(context, user),
      ],
    );
  }

  Widget _buildUserInfoRow(
    IconData icon,
    String label,
    String value,
    double fontSize,
    Map<IconData, Color> iconColors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: fontSize * 1.2, color: iconColors[icon]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: fontSize,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: fontSize * 0.95,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Botones de acción que llaman a los métodos de aceptar, editar y eliminar usuario.
  Widget _buildActionButtons(BuildContext context, User user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double iconSize = constraints.maxWidth * 0.15;
        iconSize = iconSize.clamp(20, 30);
        return Container(
          width: double.infinity,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF063970), Color(0xFF66B3FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón para aceptar usuario: muestra un diálogo para asignar rol
              _buildIconButton(Icons.check, 'Aprobar', iconSize, () {
                _showAcceptDialog(context, user);
              }),
              // Botón para editar usuario
              _buildIconButton(Icons.edit, 'Editar', iconSize, () {
                _showUserDetailsDialog(context, user, isEditing: true);
              }),
              // Botón para eliminar usuario, que muestra un alert de confirmación
              _buildIconButton(Icons.delete, 'Eliminar', iconSize, () {
                _showDeleteUserDialog(context, user);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip, double size, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: size),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  /// Diálogo para aceptar al usuario, asignándole un rol de la lista.
  void _showAcceptDialog(BuildContext context, User user) {
    final roles = Provider.of<UserPendingProvider>(context, listen: false).roles;
    String selectedRole = roles.isNotEmpty ? roles[0] : '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Asignar Rol'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Seleccione un rol para el usuario:'),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedRole,
                    isExpanded: true,
                    items: roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedRole = newValue!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                onPressed: () async {
                await Provider.of<UserPendingProvider>(context, listen: false).acceptUser(user, selectedRole);
                Navigator.pop(context);
                Provider.of<UserActiveProvider>(context, listen: false).chargeUsers();
                },
                child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Diálogo que muestra detalles del usuario y permite editarlo.
  void _showUserDetailsDialog(BuildContext context, User user, {bool isEditing = false}) {
    String name = user.name;
    String surnames = user.surnames;
    String username = user.username;
    String email = user.mail;
    String phone = user.phoneNumber;
    String address = user.address;
    bool editing = isEditing;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!editing) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: Text('$name $surnames', style: const TextStyle(fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos personales',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text('Usuario: $username'),
                      Text('Email: $email'),
                      Text('Teléfono: $phone'),
                      Text('Dirección: $address'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        editing = true;
                      });
                    },
                    child: const Text('Editar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Aprobar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Eliminar'),
                  ),
                ],
              );
            } else {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Editar usuario', style: TextStyle(fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        controller: TextEditingController(text: name),
                        onChanged: (value) {
                          name = value;
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Apellidos'),
                        controller: TextEditingController(text: surnames),
                        onChanged: (value) {
                          surnames = value;
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Usuario'),
                        controller: TextEditingController(text: username),
                        onChanged: (value) {
                          username = value;
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Email'),
                        controller: TextEditingController(text: email),
                        onChanged: (value) {
                          email = value;
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Teléfono'),
                        controller: TextEditingController(text: phone),
                        onChanged: (value) {
                          phone = value;
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Dirección'),
                        controller: TextEditingController(text: address),
                        onChanged: (value) {
                          address = value;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final updatedUser = user;
                      Provider.of<UserPendingProvider>(context, listen: false)
                          .updateUser(updatedUser, email, username);
                      Navigator.pop(context);
                    },
                    child: const Text('Guardar cambios'),
                  ),
                ],
              );
            }
          },
        );
      },
    );
  }

  /// Diálogo para confirmar la eliminación de un usuario.
  void _showDeleteUserDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar a ${user.username}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<UserPendingProvider>(context, listen: false)
                    .deleteUser(user);
                Navigator.pop(context);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
