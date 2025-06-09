import 'package:afa/design/components/side_bar_menu.dart';
import 'package:afa/design/screens/loading_no_child_screen.dart';
import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/logic/providers/active_user_provider.dart';
import 'package:afa/utils.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _surnamesController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) async 
     {
      await _loadData();
     });
    
  }

  Future<void> _loadData() async {
    await Provider.of<AuthUserProvider>(context, listen: false).loadUser();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _nameController.dispose();
    _newPasswordController.dispose();
    _surnamesController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Consumer<AuthUserProvider>(
    builder: (context, userProvider, _) {
      final user = userProvider.userFireStore;

      if (user == null) {
        return const LoadingNoChildScreen();
      }

      return Scaffold(
        drawer: const Drawer(child: SidebarMenu(selectedIndex: 1)),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          centerTitle: true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              tooltip: 'Menú',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title:                const FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                    Icon(Icons.settings, color: Colors.white, size: 30),
                    SizedBox(width: 6),
                    Text(
                      'Configuración',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFF063970),
                theme.brightness == Brightness.dark
                    ? const Color(0xFF121212)
                    : const Color(0xFF66B3FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildUserCard(context, user),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildUserCard(BuildContext context, User user) {

  return SizedBox(
    child: LayoutBuilder(
      builder: (context, constraints) {
        double fontSize = constraints.maxWidth * 0.02;
        fontSize = fontSize.clamp(22, 24);
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Wrap(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 700,
                    height: 630,
                    child: _buildUserContainer(context, user, fontSize),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildUserContainer(BuildContext context, User user, double fontSize) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: _buildUserContent(context, user, fontSize),
    ),
  );
}

Widget _buildUserContent(BuildContext context, User user, double fontSize) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Cabecera con fondo degradado y avatar
      Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF063970)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar redondeado
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3),
              ),
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.name} ${Utils().getSurnameInitials(user.surnames)}',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        size: fontSize * 0.7,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.rol,
                        style: TextStyle(
                          fontSize: fontSize * 0.7,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Icono de edición rápida
            IconButton(
              icon: Icon(Icons.edit, color: Colors.white, size: fontSize * 0.9),
              tooltip: 'Editar perfil',
              onPressed: () => _editUser(context, user),
            ),
          ],
        ),
      ),

      // Espacio entre cabecera y cuerpo
      const SizedBox(height: 12),

      if(user.rol == 'Usuario')
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _infoBadge(
                icon: Icons.alt_route,
                iconBgColor: Colors.indigo.shade600,
                label: user.numRoute == 0 ? 'Sin ruta' : 'Ruta ${user.numRoute}',
                fontSize: fontSize * 0.75,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoBadge(
                icon: Icons.person_pin_circle,
                iconBgColor: Colors.cyan.shade600,
                label: user.numPick == 0 ? 'Sin parada' : 'Parada ${user.numPick}',
                fontSize: fontSize * 0.75,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),

      // Lista de información (아이콘 + texto) dentro de un Card ligero
      Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              _buildUserInfoTile(
                icon: Icons.person,
                label: 'Usuario',
                value: user.username,
                fontSize: fontSize,
              ),
              _buildUserInfoTile(
                icon: Icons.email,
                label: 'Correo',
                value: user.mail,
                fontSize: fontSize,
              ),
              _buildUserInfoTile(
                icon: Icons.phone,
                label: 'Teléfono',
                value: user.phoneNumber,
                fontSize: fontSize,
              ),
              _buildUserInfoTile(
                icon: Icons.location_on,
                label: 'Dirección',
                value: Utils().formatAddress(user.address),
                fontSize: fontSize,
              ),
            ],
          ),
        ),
      ),

      const Spacer(),

      // Botones de acción en fila con degradado inverso
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF063970), Color(0xFF2196F3)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildIconButton(Icons.password, 'Cambiar contraseña', fontSize * 1.1, () {
                _changePassword(context, user);
              }),
            ],
          ),
        ),
      ),
    ],
  );
}

/// Badge rectangular con icono a la izquierda y texto a la derecha
Widget _infoBadge({
  required IconData icon,
  required Color iconBgColor,
  required String label,
  required double fontSize,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    decoration: BoxDecoration(
      color: iconBgColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: iconBgColor.withOpacity(0.4),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: fontSize * 1.2, color: Colors.white),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

/// ListTile personalizado para cada fila de información
Widget _buildUserInfoTile({
  required IconData icon,
  required String label,
  required String value,
  required double fontSize,
}) {
  return ListTile(
    dense: true,
    leading: Container(
      width: fontSize * 1.6,
      height: fontSize * 1.6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade50,
      ),
      child: Icon(icon, color: Colors.blue.shade400, size: fontSize * 1.0),
    ),
    title: Text(
      label,
      style: TextStyle(
        fontSize: fontSize * 0.85,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    ),
    subtitle: Text(
      value,
      style: TextStyle(
        fontSize: fontSize * 0.75,
        color: Colors.black87,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}

/// IconButton estilizado para la zona de acciones
Widget _buildIconButton(IconData icon, String tooltip, double size, VoidCallback onPressed) {
  return Tooltip(
    message: tooltip,
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size),
        onPressed: onPressed,
      ),
    ),
  );
}

  
void _changePassword(BuildContext context, User user) {
  String currentPass = '';
  String newPass = '';
  bool showCurrent = false;
  bool showNew = false;
  final formKey = GlobalKey<FormState>();

  showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          bool hasChanges() {
            return newPass.isNotEmpty && newPass != currentPass;
          }

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
                      'Cambiar Contraseña',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                ],
              ),
            ),
            content: Container(
              width: 500,
              constraints: const BoxConstraints(maxHeight: 500),
              child: Form(
                key: formKey,
                onChanged: () => setState(() {}), // Para refrescar el botón al cambiar campos
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      obscureText: !showCurrent,
                      decoration: InputDecoration(
                        labelText: 'Contraseña Actual',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showCurrent ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF063970),
                          ),
                          onPressed: () => setState(() => showCurrent = !showCurrent),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Ingresa la contraseña actual';
                        if (val != user.password) return 'Contraseña incorrecta';
                        return null;
                      },
                      onChanged: (val) => currentPass = val,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      obscureText: !showNew,
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showNew ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF063970),
                          ),
                          onPressed: () => setState(() => showNew = !showNew),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Ingresa la nueva contraseña';
                        if (val == currentPass) return 'La nueva contraseña no puede ser igual a la actual';
                        const pattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$';
                        if (!RegExp(pattern).hasMatch(val)) {
                          return 'Mínimo 8 caracteres, 1 mayúscula, 1 minúscula, 1 número y 1 símbolo';
                        }
                        return null;
                      },
                      onChanged: (val) => newPass = val,
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
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
                  const SizedBox(width: 20),
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
                        onPressed: hasChanges() && formKey.currentState?.validate() == true
                            ? () async {
                                try {
                                  await FirebaseAuth.instance.currentUser!
                                      .reauthenticateWithCredential(
                                        EmailAuthProvider.credential(
                                          email: user.mail,
                                          password: currentPass,
                                        ),
                                      );

                                  await FirebaseAuth.instance.currentUser!.updatePassword(newPass);

                                  final updatedUser = User(
                                    mail: user.mail,
                                    username: user.username,
                                    password: newPass,
                                    name: user.name,
                                    surnames: user.surnames,
                                    address: user.address,
                                    phoneNumber: user.phoneNumber,
                                    rol: user.rol,
                                    isActivate: user.isActivate,
                                    fcmToken: user.fcmToken,
                                  );
                                  Provider.of<ActiveUserProvider>(ctx, listen: false)
                                      .updateUser(updatedUser, user.mail, user.username);

                                  if (!ctx.mounted) return;

                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Contraseña cambiada correctamente'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al cambiar contraseña: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                finally 
                                {
                                  Navigator.pop(ctx);
                                  await _loadData();
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.white.withOpacity(0.2);
                            }
                            return null;
                          }),
                        ),
                        child: const Text('Cambiar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

void _editUser(BuildContext context, User user) {
  String name = user.name;
  String surnames = user.surnames;
  String username = user.username;
  String email = user.mail;
  String phone = user.phoneNumber;
  String address = user.address;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          bool hasChanges() {
            return name != user.name ||
                surnames != user.surnames ||
                username != user.username ||
                email != user.mail ||
                phone != user.phoneNumber ||
                address != user.address;
          }

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
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            content: Container(
              width: 500,
              constraints: const BoxConstraints(maxHeight: 600),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _styledTextField(
                      label: 'Nombre',
                      initialValue: name,
                      onChanged: (val) => setState(() => name = val),
                    ),
                    const SizedBox(height: 12),
                    _styledTextField(
                      label: 'Apellidos',
                      initialValue: surnames,
                      onChanged: (val) => setState(() => surnames = val),
                    ),
                    const SizedBox(height: 12),
                    _styledTextField(
                      label: 'Usuario',
                      initialValue: username,
                      onChanged: (val) => setState(() => username = val),
                    ),
                    const SizedBox(height: 12),
                    _styledTextField(
                      label: 'Email',
                      initialValue: email,
                      onChanged: (val) => setState(() => email = val),
                    ),
                    const SizedBox(height: 12),
                    _styledTextField(
                      label: 'Teléfono',
                      initialValue: phone,
                      onChanged: (val) => setState(() => phone = val),
                    ),
                    const SizedBox(height: 12),
                    _styledTextField(
                      label: 'Dirección',
                      initialValue: address,
                      onChanged: (val) => setState(() => address = val),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
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
                        const SizedBox(width: 20),
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
                              onPressed: hasChanges()
                                  ? () async {
                                    try
                                    {
                                      User updatedUser = User(
                                        mail: email,
                                        username: username,
                                        password: user.password,
                                        name: name,
                                        surnames: surnames,
                                        address: address,
                                        phoneNumber: phone,
                                        rol: user.rol,
                                        isActivate: user.isActivate,
                                        fcmToken: user.fcmToken,
                                      );
                                      Provider.of<ActiveUserProvider>(ctx, listen: false)
                                          .updateUser(updatedUser, user.mail, user.username);

                                      if (!ctx.mounted) return;
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text('Información actualizada correctamente'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                    catch (e) {
                                      if (!ctx.mounted) return;
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text('No se pudo actualizar la información: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                    finally 
                                    {
                                      Navigator.pop(ctx);
                                      await _loadData();
                                    }
                                  }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ).copyWith(
                                overlayColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.hovered)) {
                                    return Colors.white.withOpacity(0.2);
                                  }
                                  return null;
                                }),
                              ),
                              child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Este campo es obligatorio';
      }
      return null;
    },
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
