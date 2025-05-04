import 'dart:async';
import 'dart:ui';
import 'package:afa/logic/providers/register_provider.dart';
import 'package:afa/logic/router/path/path_url_afa.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin 
{
  bool _isPasswordVisible = false;
  bool _termsAccepted = false;
  bool _fcmAccepted = false;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnamesController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  late String _fcmToken = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() 
  {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _mailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _surnamesController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<String?> _requestNotificationPermission() async 
  {
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
  if (settings.authorizationStatus == AuthorizationStatus.authorized) 
  {
    _fcmAccepted = true;
    
    return await FirebaseMessaging.instance.getToken();
  } 
  else 
  {
    _fcmAccepted = false;
    ScaffoldMessenger.of(context).showSnackBar
    (
      const SnackBar(
        content: Text('El servicio de notificaciones está denegado.'),
        backgroundColor: Colors.red,
      ),
    );
    return '';
  }
}

  Future<Position?> _requestLocationPermission() async 
  {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El servicio de ubicación está desactivado.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Los permisos de ubicación fueron denegados.'),
            backgroundColor: Colors.red,
          ),
        );
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los permisos de ubicación están permanentemente denegados.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
    return await Geolocator.getCurrentPosition();
  }

  void _registerUser(RegisterProvider registerProvider) async 
  {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) 
    {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));

      Position? position = await _requestLocationPermission();
      if (position == null) 
      {
        setState(() => _isLoading = false);
        return;
      }

      _fcmToken = (await _requestNotificationPermission())!;
      if(_fcmToken == ''){
        setState(() => _isLoading = false);
        return;
      }

      String address = registerProvider.joinAddress(
        _streetController.text,
        registerProvider.selectedCity ?? "",
        registerProvider.selectedProvince ?? "",
        _postalCodeController.text,
      );

      await registerProvider.registerUser(
        mail: _mailController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        name: registerProvider.capitalizeEachWord(_nameController.text),
        surnames: registerProvider.capitalizeEachWord(_surnamesController.text),
        address: registerProvider.capitalizeEachWord(address),
        phoneNumber: _phoneController.text,
        fcmToken: _fcmToken,
      );

      _formKey.currentState!.validate();

      if (registerProvider.errorMail == "" &&
          registerProvider.errorUser.trim() == "" && 
          _termsAccepted && _fcmAccepted)
      {
        showSubmittedDialog(context);
        _mailController.clear();
        _usernameController.clear();
        _passwordController.clear();
        _nameController.clear();
        _surnamesController.clear();
        _phoneController.clear();
        _streetController.clear();
        _postalCodeController.clear();
      }
      setState(() => _isLoading = false);
    }
  }

  void showSubmittedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF063970)),
              SizedBox(width: 10),
              Text('Formulario enviado'),
            ],
          ),
          content: const Text(
            'Tu solicitud ha sido enviada al administrador. ¡Gracias!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF063970)),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  final userRegisterProvider = Provider.of<RegisterProvider>(context);
  final theme = Theme.of(context);

  final double screenWidth = MediaQuery.of(context).size.width;
  const double verticalMargin = 40;

  final bool isMobile = screenWidth < 600;
  final double containerWidth = isMobile ? screenWidth * 0.9 : (screenWidth * 0.95 > 900 ? 900 : screenWidth * 0.95);

  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 80,
      leading: Tooltip(
        message: 'Volver al inicio',
        child: IconButton(
          onPressed: () {
            context.go(PathUrlAfa().pathWelcome);
          },
          icon: Image.asset(
            'assets/images/logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
          iconSize: 70,
        ),
      ),
    ),
    body: Stack(
      children: [
        // Fondo de mapa + blur
        Positioned.fill(
          child: Image.asset(
            'assets/images/map_background.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        // Contenedor con formulario
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: verticalMargin),
            child: Center(
              child: SingleChildScrollView(
                child: SizedBox(
                  width: containerWidth,
                  // El formulario sigue desplazándose sin interferir con el footer
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0), // Padding alrededor
                      child: _buildRegisterForm(userRegisterProvider, theme),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Footer fijo, siempre visible
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black54,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              '© 2025 AFA Andújar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildRegisterForm(
    RegisterProvider registerProvider,
    ThemeData theme,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Encabezado con degradado y título
          Container(
            width: double.infinity,
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
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text(
              'Registro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Cuerpo del formulario
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFloatingTextField(
                  label: 'Correo Electrónico',
                  hint: 'ejemplo@correo.com',
                  controller: _mailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) async {
                    if (value.trim().isNotEmpty &&
                        registerProvider.isCorrectMail(value)) {
                      bool exists = await registerProvider.mailExists(value);
                      if (exists) {
                        registerProvider.errorMail = "El correo ya existe";
                      } else {
                        registerProvider.errorMail = "";
                      }
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Este campo es obligatorio";
                    }
                    if (!registerProvider.isCorrectMail(value)) {
                      return "Introduce un correo válido";
                    }
                    if (registerProvider.errorMail.trim().isNotEmpty) {
                      return registerProvider.errorMail.trim();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildFloatingTextField(
                  label: 'Usuario',
                  hint: 'cartogar64',
                  controller: _usernameController,
                  onChanged: (value) async {
                    if (value.trim().isNotEmpty) {
                      bool exists =
                          await registerProvider.usernameExists(value);
                      if (exists) {
                        registerProvider.errorUser ="El usuario ya existe";
                      } else {
                        registerProvider.errorUser = "";
                      }
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Este campo es obligatorio";
                    }
                    if (registerProvider.errorUser.trim().isNotEmpty) {
                      return registerProvider.errorUser.trim();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildFloatingPasswordField(
                  _passwordController,
                  registerProvider,
                  theme,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Datos Personales',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF063970),
                  ),
                ),
                const SizedBox(height: 10),
                _buildFloatingTextField(
                  label: 'Nombre',
                  hint: 'Carlos',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Este campo es obligatorio";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildFloatingTextField(
                  label: 'Apellidos',
                  hint: 'Toril García',
                  controller: _surnamesController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Este campo es obligatorio";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                _buildFloatingTextField(
                  label: 'Teléfono',
                  hint: '645323211',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Este campo es obligatorio";
                    }
                    if (!RegExp(r'^[0-9]{9}$').hasMatch(value)) {
                      return "El teléfono debe tener 9 dígitos";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dirección',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF063970),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildFloatingTextField(
                        label: 'Calle',
                        hint: 'Calle Leonardo Da Vinci, 40, 2ºE',
                        controller: _streetController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Este campo es obligatorio";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildFloatingTextField(
                        label: 'Código Postal',
                        hint: '23740',
                        controller: _postalCodeController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Este campo es obligatorio";
                          }
                          if (!RegExp(r'^[0-9]{5}$').hasMatch(value)) {
                            return "El código postal debe tener 5 dígitos";
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _buildFloatingDropdown(
                        label: 'Provincia',
                        hint: 'Seleccione provincia',
                        value: registerProvider.selectedProvince,
                        items: registerProvider.provinces,
                        onChanged: (newValue) {
                          if (newValue != null) {
                            registerProvider.setSelectedProvince(newValue);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Seleccione una provincia';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildFloatingDropdown(
                        label: 'Ciudad',
                        hint: 'Seleccione ciudad',
                        value: registerProvider.selectedCity,
                        items: registerProvider.cities,
                        onChanged: (newValue) {
                          if (newValue != null) {
                            registerProvider.setSelectedCity(newValue);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) 
                          {
                            return 'Seleccione una ciudad';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Acepto los términos y condiciones',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            _registerUser(registerProvider);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF063970),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(0, 50),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Registrarse',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.go(PathUrlAfa().pathLogin);
                    },
                    child: const Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style:
                          TextStyle(color: Color(0xFF063970), fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      cursorColor: const Color(0xFF063970),
      validator: validator,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF063970)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF063970), width: 2),
        ),
        labelStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Color(0xFF063970),
        ),
      ),
    );
  }

  Widget _buildFloatingPasswordField(
    TextEditingController controller,
    RegisterProvider registerProvider,
    ThemeData theme,
  ) {
    return TextFormField(
      controller: controller,
      cursorColor: const Color(0xFF063970),
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Este campo es obligatorio";
        }
        if (!registerProvider.isSecurePassword(value)) {
          return "La contraseña no es segura. Debe tener al menos 8 caracteres, \n"
              "incluir mayúsculas, minúsculas, dígitos y un carácter especial.";
        }
        return null;
      },
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        hintText: 'Contraseña',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF063970), width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF063970),
            size: 28,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        labelStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Color(0xFF063970),
        ),
      ),
    );
  }

  Widget _buildFloatingDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 18)),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF063970), width: 2),
        ),
        labelStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Color(0xFF063970),
        ),
      ),
    );
  }
}