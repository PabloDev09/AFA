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
        drawer: const Drawer(child: SidebarMenu(selectedIndex: 2)),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildUserCard(context, user),
            ),
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
                    width: 350,
                    height: 330,
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
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          '${user.numRoute}',
                          style: TextStyle(
                            fontSize: fontSize * 0.8,
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
                          '${user.numPick}',
                          style: TextStyle(
                            fontSize: fontSize * 0.8,
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
          ],
        ),
      ),
      const Divider(),
      SingleChildScrollView(
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
      const Spacer(),
      const SizedBox(height: 4),
      _buildActionButtons(context, user),
    ],
  );
}

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
            size: fontSize * 1.2,
            color: iconColors[icon],
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
            _buildIconButton(Icons.edit, 'Editar', iconSize, () {
              _editUser(context, user);
            }),
            _buildIconButton(Icons.password, 'Cambiar contraseña', iconSize, () {
              _changePassword(context, user);
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
