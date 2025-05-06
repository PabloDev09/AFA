import 'dart:ui';
import 'package:afa/logic/providers/active_user_provider.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:afa/logic/router/afa_router.dart';
import 'package:afa/logic/router/path/path_url_afa.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  
  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Método que navega a la pantalla correspondiente según el rol del usuario.
 Future<void> _navigateAccordingToRole(String email) async {


  // Carga el rol y lo almacena globalmente
  final role = await getUserRole();
  Provider.of<AuthUserProvider>(context,listen: false).loadUser();
  if(mounted){
    if (role == 'Admin') {
      context.go(PathUrlAfa().pathDashboard);
    } else if (role == 'Conductor') {
      context.go(PathUrlAfa().pathHome);
    } else if (role == 'Usuario') {
      context.go(PathUrlAfa().pathHome);
    } else {
    ScaffoldMessenger.of(context).showSnackBar
    (
      const SnackBar(
        content: Text('Rol de usuario desconocido.'),
        backgroundColor: Colors.red,
      ),
    );
    }
  }
}


  Future<void> _signInWithGoogle() async {
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId: '253008576813-licpgrjsnuhh9i918tlrda6veitsg0c6.apps.googleusercontent.com',
      ).signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Autenticamos en Firebase primero
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final String email = googleUser.email;

      // Llamamos a authenticateGoogleUser y esperamos su resultado
      final bool isValidUser = await Provider.of<ActiveUserProvider>(
        context,
        listen: false,
      ).authenticateGoogleUser(email);

      // Si no es válido, eliminamos y deslogueamos
      if (!isValidUser) 
      {
        await userCredential.user?.delete(); // Elimina de FirebaseAuth
        await FirebaseAuth.instance.signOut(); // Cierra sesión
        await GoogleSignIn().signOut(); // Cierra sesión de Google también

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuario no autorizado, sesión cerrada.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Si todo está bien, navega
      _navigateAccordingToRole(email);
  }


  Widget _buildLoginForm() {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabecera con degradado y título
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
              'Iniciar sesión',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Cuerpo blanco con campos y botones
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFloatingTextField(
                  label: 'Correo',
                  hint: 'Ingresa tu correo',
                  controller: _userController,
                ),
                const SizedBox(height: 15),
                _buildFloatingPasswordField(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF063970),
                          Color(0xFF2196F3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final userActiveProvider = Provider.of<ActiveUserProvider>(
                            context,
                            listen: false,
                          );
                          bool isAuthenticated = await userActiveProvider.authenticateUser(
                            _userController.text.trim(),
                            _passwordController.text.trim(),
                          );
                          if (isAuthenticated) {
                            await FirebaseAuth.instance.signInWithEmailAndPassword(
                              email: _userController.text.trim(),
                              password: _passwordController.text.trim(),
                            );
                            _navigateAccordingToRole(_userController.text);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('El usuario o la contraseña son incorrectos.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(0, 50),
                        ).copyWith(
                          overlayColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return Colors.white.withOpacity(0.2);
                            }
                            return null;
                          }),
                        ),
                      child: const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Colors.black12),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                    ),
                    label: const Text(
                      'Continuar con Google',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.go(PathUrlAfa().pathRegister);
                    },
                    child: const Text(
                      '¿No tienes cuenta? Regístrate',
                      style: TextStyle(color: Color(0xFF063970), fontSize: 16),
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

  /// Campo de texto con label flotante
  Widget _buildFloatingTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: Colors.blue,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo no puede estar vacío';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(),
      ),
    );
  }

  /// Campo de contraseña con label flotante y control de visibilidad
  Widget _buildFloatingPasswordField() {
    return TextFormField(
      controller: _passwordController,
      cursorColor: Colors.blue,
      obscureText: !_isPasswordVisible,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo no puede estar vacío';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Contraseña',
        hintText: 'Ingresa tu contraseña',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF063970),
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final double screenWidth = MediaQuery.of(context).size.width;
    final double containerWidth = screenWidth * 0.9 > 900 ? 900 : screenWidth * 0.9;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // leadingWidth menor para que el hover sea más pequeño
        leadingWidth: 80,
        leading: Tooltip(
          message: 'Volver al inicio',
          child: IconButton(
            onPressed: () {
              context.go(PathUrlAfa().pathWelcome);
            },
            // Reemplazamos el icon por la imagen en sí, sin fondo
            icon: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
            // Ajustamos el iconSize para que el hover sea más pequeño
            iconSize: 70,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Fondo con mapa + blur
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
          // Contenedor principal con el formulario
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Container(
                    width: containerWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _buildLoginForm(),
                  ),
                ),
              ),
            ),
          ),
          // Footer superpuesto (pequeño)
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
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
