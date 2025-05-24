import 'package:afa/design/screens/loading_no_child_screen.dart';
import 'package:afa/logic/providers/active_user_provider.dart';
import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/design/components/side_bar_menu.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final bool _isVerifying = false;
  final bool _showEditForm = false;
  final bool _wrongPassword = false;
  final bool _isPasswordVisible = false;
  final _passwordController = TextEditingController();

  late Future<void> _initialLoad;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _surnamesController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  void initState() {
    super.initState();
    _initialLoad = (() async {
      await Provider.of<AuthUserProvider>(context, listen: false).loadUser();
      await _loadData();
    })();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthUserProvider>(context, listen: false);
    final userRouteProvider =
        Provider.of<UserRouteProvider>(context, listen: false);

    await authProvider.loadUser();
    final username = authProvider.userFireStore?.username;
    if (username != null) {
      userRouteProvider.startListening();
      await userRouteProvider.getCancelDates(username);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _nameController.dispose();
    _surnamesController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder(
      future: _initialLoad,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: LoadingNoChildScreen()),
          );
        }

        final user = Provider.of<AuthUserProvider>(context).userFireStore!;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: _isMenuOpen
                ? const Color.fromARGB(30, 0, 0, 0)
                : Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isMenuOpen ? Icons.close : Icons.menu,
                    color: _isMenuOpen ? Colors.blue[700] : Colors.white,
                  ),
                  onPressed: _toggleMenu,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Ajustes",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: _buildBody(context, user, theme),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, User user, ThemeData theme) {
    return Stack(
      children: [
        Container(
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          spreadRadius: 1,
                          offset: Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "${user.name} ${user.surnames}",
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoRow(Icons.person, "Usuario", user.username),
                        _infoRow(Icons.email, "Correo", user.mail),
                        _infoRow(Icons.phone, "Teléfono", user.phoneNumber),
                        _infoRow(Icons.location_on, "Dirección", user.address),
                        const SizedBox(height: 20),
                        if (!_isVerifying && !_showEditForm)
                          Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ElevatedButton(
                                onPressed: () {
                                  _showPasswordDialog(user);
                                },
                                child: const Text("Modificar datos"),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
        if (_isMenuOpen)
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SidebarMenu(selectedIndex: 3),
          ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value),
            ),
          ),
        ],
      ),
    );
  }

  void _showPasswordDialog(User user) {
    showDialog(
      context: context,
      builder: (context) {
        bool localWrongPassword = _wrongPassword;
        bool localIsPasswordVisible = _isPasswordVisible;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Confirmar contraseña',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Introduce tu contraseña para continuar:",
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !localIsPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      hintText: 'Ingresa tu contraseña',
                      errorText: localWrongPassword ? "Contraseña incorrecta" : null,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          localIsPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF063970),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            localIsPasswordVisible = !localIsPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("Cancelar"),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final isValid =
                        await Provider.of<AuthUserProvider>(context, listen: false)
                            .verifyPassword(user.mail, _passwordController.text);

                    if (isValid) {
                      Navigator.of(context).pop();
                      _nameController.text = user.name;
                      _surnamesController.text = user.surnames;
                      _phoneController.text = user.phoneNumber;
                      _addressController.text = user.address;
                      _showEditDialog(user);
                    } else {
                      setDialogState(() {
                        localWrongPassword = true;
                      });
                    }
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("Verificar"),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(User user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Editar usuario',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  TextFormField(
                    controller: _surnamesController,
                    decoration: const InputDecoration(labelText: 'Apellidos'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Campo obligatorio' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("Cancelar"),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final updatedUser = User(
                    mail: user.mail,
                    username: user.username,
                    password: _newPasswordController.text,
                    name: _nameController.text,
                    surnames: _surnamesController.text,
                    phoneNumber: _phoneController.text,
                    address: _addressController.text,
                    rol: user.rol,
                    isActivate: user.isActivate,
                    fcmToken: user.fcmToken,
                  );

                  Provider.of<ActiveUserProvider>(context, listen: false)
                      .updateUser(updatedUser, user.mail, user.username);

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Datos actualizados correctamente."),
                  ));
                }
              },
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("Guardar cambios"),
              ),
            ),
          ],
        );
      },
    );
  }
}
