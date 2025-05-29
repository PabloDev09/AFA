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
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
  }
  
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
    if (role == 'Administrador' || role == 'Conductor' || role == 'Usuario')
     {
      context.go(PathUrlAfa().pathHome);
    }
    else {
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

  final googleAuth = await googleUser.authentication;
  final oauthCredential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  // 1) Comprobamos los métodos de sign-in para este email
  final email = googleUser.email;
  final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

  if (methods.contains('password')) {
    // 2) Si existe email/password, pedimos la contraseña para vincular
    String? pwd = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Introduce tu contraseña'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Vincular cuentas'),
            ),
          ],
        );
      },
    );

    if (pwd == null || pwd.isEmpty) return;
    
    try {
      // 3) Iniciamos sesión con email/password para obtener la user
      final emailUserCred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pwd);

      // 4) Vinculamos la credencial de Google a ese user
      await emailUserCred.user?.linkWithCredential(oauthCredential);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta vinculada con éxito.'),
          backgroundColor: Colors.green,
        ),
      );
      Provider.of<AuthUserProvider>(context,listen: false).loadUser();
      _navigateAccordingToRole(email);
      return;
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error vinculando cuentas: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  // 5) Si no existía email/password, simplemente autenticamos con Google
  await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  
  Provider.of<AuthUserProvider>(context,listen: false).loadUser();
  // Aquí puedes validar con tu provider si quieres o navegar directo:
  _navigateAccordingToRole(email);
}

/// Lógica principal de login/email↔Google link
Future<void> _signInWithMailAndPassword() async {
  if (_isLoading) {
    return;
  }
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() => _isLoading = true);
  final email = _userController.text.trim();
  final pwd = _passwordController.text.trim();

  final provider = Provider.of<ActiveUserProvider>(context, listen: false);
  final authProvider = Provider.of<AuthUserProvider>(context, listen: false);

  // 1) Autenticación personalizada
  final isAuthenticated = await provider.authenticateUser(email, pwd);
  if (!isAuthenticated) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usuario o contraseña no válidos.'),
        backgroundColor: Colors.red,
      ),
    );
    setState(() => _isLoading = false);
    return;
  }

  try {
    // 2) Obtener proveedores en Firebase
    final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

    if (methods.contains('password')) {
      // Tiene email/password → login directo
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pwd);

    } else if (methods.contains('google.com')) {
      // Ya existe solo con Google → intentar password login por si ya está linkeado
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pwd);
      } on FirebaseAuthException {
        // Si el login con contraseña falla, se procede a vincular
        await _maybeLinkGoogleIfNotAlready(email, pwd);
      }

    } else {
      // No existe → crear cuenta con email/password
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pwd);
      } on FirebaseAuthException catch (e2) {
        if (e2.code == 'email-already-in-use') {
          // 1) Intentar login directo con email/password
          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pwd);
          } on FirebaseAuthException {
            // Solo aquí realizamos el flujo de link
            await _maybeLinkGoogleIfNotAlready(email, pwd);
          }
          // En ambos casos (login directo o link), ya estamos autenticados
          authProvider.loadUser();
          _navigateAccordingToRole(email);
          return;
        } else {
          rethrow;
        }
      }
    }

    // 3) Tras login/create/link exitoso → cargar y navegar
    authProvider.loadUser();
    _navigateAccordingToRole(email);

  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error de autenticación: ${e.message}'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

/// Verifica si el usuario actual ya tiene link con email/password;
/// si no, ofrece diálogo y realiza el link
Future<void> _maybeLinkGoogleIfNotAlready(String email, String password) async {
  // Comprueba el usuario actualmente autenticado
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    final providers = currentUser.providerData.map((p) => p.providerId).toList();
    // Si ya está vinculado con email/password, saltar
    if (providers.contains('password')) 
    {
      return;
    }
  }

  // Mostrar diálogo de confirmación para vincular
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
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
                'Vincular con Google',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
      content: const Text('Tu cuenta existe con Google. ¿Deseas vincular también tu contraseña?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton.icon(
          icon: Image.asset('assets/images/google_logo.png', height: 18),
          label: const Text('Vincular', style: TextStyle(color: Colors.black)),
          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  // Sign-in con popup de Google para obtener credenciales frescas
  final googleProvider = GoogleAuthProvider();
  final result = await FirebaseAuth.instance.signInWithPopup(googleProvider);
  final user = result.user!;
  
  // Link de la credencial de email/password
  final emailCred = EmailAuthProvider.credential(email: email, password: password);
  try {
    await user.linkWithCredential(emailCred);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cuenta vinculada con éxito.'), backgroundColor: Colors.green, duration: Duration(seconds: 2),),
    );
  } on FirebaseAuthException catch (e) {
    if (e.code != 'credential-already-in-use') rethrow;
  }
  await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
}

 Widget _buildLoginForm() 
 {
    double fontSize;
    if(MediaQuery.of(context).size.width <= 500 && MediaQuery.of(context).size.width >= 430)
    {
      fontSize = 16;
    }
    else if(MediaQuery.of(context).size.width < 430)
    {
      fontSize = 12;
    }
    else
    {
      fontSize = 20;
    }


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
                    onPressed: _signInWithMailAndPassword,
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
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
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
                  label: Text(
                    'Continuar con Google',
                    style: TextStyle(fontSize: fontSize),
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
                    textAlign: TextAlign.center,
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