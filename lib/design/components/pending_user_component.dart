import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/providers/active_user_provider.dart';
import 'package:afa/logic/providers/pending_user_provider.dart';
import 'package:afa/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class PendingUserComponent extends StatelessWidget {
  const PendingUserComponent({super.key});

@override
Widget build(BuildContext context) {
  return Consumer<PendingUserProvider>(
    builder: (context, pendingUserProvider, _) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
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
          ),
          const SizedBox(height: 20),
          if (pendingUserProvider.pendingUsers.isEmpty)
            _buildNoUsersDirectly(context)
          else
            _buildPendingUsersCards(context, pendingUserProvider.pendingUsers),
          const SizedBox(height: 20),
        ],
      );
    },
  );
}


  Widget _buildNoUsersDirectly(BuildContext context) {
  return SizedBox(
    height: MediaQuery.of(context).size.height * 0.7,
    child: const Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
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
            SizedBox(height: 20),
            Text(
              'No hay peticiones de registro',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'En cuanto existan usuarios pendientes se mostrarán aquí.',
              style: TextStyle(
                fontSize: 20,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

 Widget _buildPendingUsersCards(BuildContext context, List<User> pendingUsers) {

  return SizedBox(
    child: LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        double fontSize = constraints.maxWidth * 0.02;
        fontSize = fontSize.clamp(22, 24);

        double columnFactor = constraints.maxWidth / 375;
        columns = columnFactor.floor().clamp(1, pendingUsers.length);
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
              height: 330,
              child: _buildUserContainer(context, user, fontSize),
            );
          }).toList(),
        );
      },
    ),
  );
}

  /// Contenedor interno. Va dentro de un SizedBox.
  Widget _buildUserContainer(BuildContext context, User user, double fontSize) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
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
        // Cabecera con nombre y botón de llamada
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${user.name} ${Utils().getSurnameInitials(user.surnames)}',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Column(
              children: [
                _buildUserInfoRow(Icons.person, user.username, fontSize, iconColors),
                _buildUserInfoRow(Icons.email, user.mail, fontSize, iconColors),
                _buildUserInfoRow(Icons.phone, user.phoneNumber, fontSize, iconColors),
                _buildUserInfoRow(Icons.location_on, Utils().formatAddress(user.address), fontSize, iconColors),
              ],
            ),
          ),
        ),
        _buildActionButtons(context, user),
      ],
    );
  }

  /// Fila de información para cada dato (usuario, email, etc.).
Widget _buildUserInfoRow(
  IconData icon,
  String value,
  double fontSize,
  Map<IconData, Color> iconColors,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: fontSize * 1.2, // Tamaño fijo para todos los íconos
            color: iconColors[icon],
          ),
          const SizedBox(width: 8),
          // Solo el texto se escala
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: fontSize * 1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
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
              _buildIconButton(Icons.call, 'Llamar', iconSize, () {
                _callUser(context, user);
              }),
              // Botón para aceptar usuario: muestra un diálogo para asignar rol
              _buildIconButton(Icons.check, 'Aprobar', iconSize, () {
                _approveUser(context, user);
              }),
              // Botón para editar usuario
              _buildIconButton(Icons.edit, 'Editar', iconSize, () {
                _editUser(context, user);
              }),
              // Botón para eliminar usuario, que muestra un alert de confirmación
              _buildIconButton(Icons.delete, 'Eliminar', iconSize, () {
                _deleteUser(context, user);
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

  void _approveUser(BuildContext context, User user) {
  final roles = Provider.of<PendingUserProvider>(context, listen: false).rols;
  String selectedRole = roles.isNotEmpty ? roles[0] : '';

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            titlePadding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            title: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF063970), Color(0xFF2196F3)],
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
                  const Expanded(
                    child: Text(
                      'Aprobar usuario',
                      style: TextStyle(
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccione un rol para el usuario:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
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
                  ),
                ),
              ],
            ),
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF063970), Color(0xFF2196F3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          await Provider.of<PendingUserProvider>(context, listen: false)
                              .approveUser(user, selectedRole);
                          Navigator.pop(context);
                          Provider.of<ActiveUserProvider>(context, listen: false).loadActiveUsers();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.white.withOpacity(0.2);
                            }
                            return null;
                          }),
                        ),
                        child: const Text(
                          'Aprobar',
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
          );
        },
      );
    },
  );
}


    /// Abre un diálogo de detalles y edición del usuario.
  void _editUser(BuildContext context, User user) {
    String name = user.name;
    String surnames = user.surnames;
    String username = user.username;
    String email = user.mail;
    String phone = user.phoneNumber;
    String address = user.address;


    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                titlePadding: EdgeInsets.zero,
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                title: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF063970), Color(0xFF2196F3)],
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
                      const Expanded(
                        child: Text(
                          'Editar usuario',
                          style: TextStyle(
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
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _styledTextField(
                        label: 'Nombre',
                        initialValue: name,
                        onChanged: (val) => name = val,
                      ),
                      const SizedBox(height: 12),
                      _styledTextField(
                        label: 'Apellidos',
                        initialValue: surnames,
                        onChanged: (val) => surnames = val,
                      ),
                      const SizedBox(height: 12),
                      _styledTextField(
                        label: 'Usuario',
                        initialValue: username,
                        onChanged: (val) => username = val,
                      ),
                      const SizedBox(height: 12),
                      _styledTextField(
                        label: 'Email',
                        initialValue: email,
                        onChanged: (val) => email = val,
                      ),
                      const SizedBox(height: 12),
                      _styledTextField(
                        label: 'Teléfono',
                        initialValue: phone,
                        onChanged: (val) => phone = val,
                      ),
                      const SizedBox(height: 12),
                      _styledTextField(
                        label: 'Dirección',
                        initialValue: address,
                        onChanged: (val) => address = val,
                      ),
                      const SizedBox(height: 24),
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
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF063970), Color(0xFF2196F3)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  final updatedUser = User(
                                    mail: email,
                                    username: username,
                                    password: user.password,
                                    name: name,
                                    surnames: surnames,
                                    address: address,
                                    phoneNumber: phone,
                                    rol: user.rol,
                                    isActivate: user.isActivate,
                                  );
                                  Provider.of<ActiveUserProvider>(context, listen: false)
                                      .updateUser(updatedUser, email, username);
                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ).copyWith(
                                  overlayColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.hovered)) {
                                      return Colors.white.withOpacity(0.2);
                                    }
                                    return null;
                                  }),
                                ),
                                child: const Text(
                                  'Guardar cambios',
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
                ),
              );
            
          },
        );
      },
    );
  }
  
  Widget _styledTextField({
  required String label,
  required String initialValue,
  required Function(String) onChanged,
}) {
 return TextFormField(
    controller: TextEditingController(text: initialValue),
    cursorColor: Colors.blue,
    decoration: InputDecoration(
    labelText: label,
    hintText: label,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    border: const OutlineInputBorder(),
    ),
  );
}

void _deleteUser(BuildContext context, dynamic user) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFE53935)], 
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
            const Expanded(
              child: Text(
                'Rechazar usuario',
                style: TextStyle(
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
      content: Text('¿Deseas rechazar a ${user.username}? Esta acción no se puede deshacer.'),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Provider.of<PendingUserProvider>(context, listen: false)
                        .removeUser(user);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.white.withOpacity(0.2);
                        }
                        return null;
                      }),
                    ),
                  child: const Text(
                    'Rechazar',
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
    Future<void> _callUser(BuildContext context, User user) async {
    final uri = Uri(scheme: 'tel', path: user.phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('No se pudo lanzar el marcador: $uri');
    }
  }
}
