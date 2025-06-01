import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/providers/active_user_provider.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveUserComponent extends StatelessWidget {
  const ActiveUserComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveUserProvider>(
      builder: (context, activeUserProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              const SizedBox(height: 10),
              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person, color: Colors.white, size: 30),
                    SizedBox(width: 6),
                    Text(
                      'Usuarios Activos',
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
            // Si no hay usuarios, se muestra un mensaje centrado
            if (activeUserProvider.activeUsers.isEmpty)
              _buildNoUsersDirectly(context)
            else
              _buildActiveUsersCards(context, activeUserProvider.activeUsers),
          ],
        );
      },
    );
  }

  Widget _buildNoUsersDirectly(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;

  return SizedBox(
    height: screenHeight * 0.7,
    child: const Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono principal para usuarios activos con X roja superpuesta en la esquina superior derecha
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.people_alt_rounded,
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
              'No hay usuarios activos',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'En cuanto existan usuarios activos se mostrarán aquí.',
              style: TextStyle(
                fontSize: 16,
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


  Widget _buildActiveUsersCards(BuildContext context, List<User> activeUsers) {

  return SizedBox(
    child: LayoutBuilder(
      builder: (context, constraints) {
        int columns;
        double fontSize = constraints.maxWidth * 0.02;
        fontSize = fontSize.clamp(22, 24);

        double columnFactor = constraints.maxWidth / 375;
        columns = columnFactor.floor().clamp(1, activeUsers.length);
        double decimalPart = columnFactor - columns;
        fontSize = (fontSize + decimalPart * 6).clamp(22, 25);

        const double spacing = 16;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: activeUsers
              .where((user) => user.mail != Provider.of<AuthUserProvider>(context, listen: false).userFireStore?.mail && user.username != Provider.of<AuthUserProvider>(context, listen: false).userFireStore?.username) 
              .map((user) {
                return SizedBox(
                  width: 350,
                  height: 330,
                  child: _buildUserContainer(context, user, fontSize),
                );
              }).toList(),
        );
      },
    ),
  );
}


  /// Contenedor interno para cada usuario activo.
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

  /// Muestra la información del usuario activo, incluyendo su rol.
  /// Se ha modificado para que los botones de acción queden siempre en la parte inferior.
Widget _buildUserContent(BuildContext context, User user, double fontSize) {
  Map<IconData, Color> iconColors = {
    Icons.person: Colors.blue.shade300,
    Icons.email: Colors.green.shade300,
    Icons.phone: Colors.orange.shade300,
    Icons.location_on: Colors.red.shade300,
    // Rol eliminado de aquí
  };

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Cabecera con nombre, rol y chips de ruta/parada
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre y Rol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.name} ${Utils().getSurnameInitials(user.surnames)}',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Tooltip(
                  message: 'Rol',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.security,
                        size: fontSize * 0.6,
                        color: Colors.purple.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.rol,
                        style: TextStyle(
                          fontSize: fontSize * 0.6,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
            if(user.rol == 'Usuario')...[
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [ 
                    Tooltip(
                      message: 'Ruta',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.alt_route,
                            size: fontSize * 0.8,
                            color: Colors.indigo.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.numRoute == 0 ? 'Sin asignar' : '${user.numRoute}',
                            style: TextStyle(
                              fontSize: user.numRoute == 0 ? fontSize * 0.65: fontSize * 0.8,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Tooltip(
                      message: 'Parada',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: fontSize * 0.8,
                            color: Colors.cyan.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.numPick == 0 ? 'Sin asignar' : '${user.numPick}',
                            style: TextStyle(
                              fontSize: user.numPick == 0 ? fontSize * 0.65 : fontSize * 0.8,
                              fontWeight: FontWeight.w600,
                              color: Colors.cyan.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),

      const Divider(),

      // Lista de filas de información (sin el rol)
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Column(
            children: [
              _buildUserInfoRow(Icons.person,'Usuario', user.username, fontSize, iconColors),
              _buildUserInfoRow(Icons.email,'Correo', user.mail, fontSize, iconColors),
              _buildUserInfoRow(Icons.phone,'Teléfono', user.phoneNumber, fontSize, iconColors),
              _buildUserInfoRow(Icons.location_on,'Dirección', Utils().formatAddress(user.address), fontSize, iconColors),
            ],
          ),
        ),
      ),
      _buildActionButtons(context, user),
    ],
  );
}




/// Fila de información para cada dato (usuario, email, etc.) con Tooltip.
Widget _buildUserInfoRow(
  IconData icon,
  String label,
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
          Tooltip(
            message: label,
            child: Icon(
              icon,
              size: fontSize * 1.2, 
              color: iconColors[icon],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: fontSize * 0.8,
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


  /// Botones de acción: Dar de baja, Editar y Eliminar.
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
              colors: [Color(0xFF063970), Color(0xFF2196F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón para dar de baja
              _buildIconButton(Icons.call, 'Llamar', iconSize, () {
                _callUser(context, user);
              }),
              // Botón para editar
              _buildIconButton(Icons.edit, 'Editar', iconSize, () {
                _editUser(context, user);
              }),
              // Botón para eliminar
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

  Future<void> _callUser (BuildContext context, dynamic user) async
  {
    final uri = Uri(scheme: 'tel', path: user.phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      debugPrint('No se pudo lanzar el marcador: $uri');
    }
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
            colors: [Color(0xFFB71C1C), Color(0xFFE53935)], // Rojo degradado
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
                'Eliminar usuario',
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
      content: Text('¿Deseas eliminar a ${user.username}? Esta acción no se puede deshacer.'),
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
                    Provider.of<ActiveUserProvider>(context, listen: false)
                        .deleteUser(user);
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
                    'Eliminar',
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


}