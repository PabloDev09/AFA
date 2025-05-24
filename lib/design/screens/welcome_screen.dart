import 'dart:async';
import 'dart:ui';
import 'package:afa/logic/router/path/path_url_afa.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final bool isSmallScreen = screenWidth < 500;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/map_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.25),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isSmallScreen = constraints.maxWidth < 500;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: isSmallScreen ? 40 : 20),
                          padding: EdgeInsets.all(isSmallScreen ? 28 : 10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: isSmallScreen ? 260 : 130,
                            fit: BoxFit.contain,
                          ),
                        ),

                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            margin: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 30 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 20,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF063970),
                                        Color(0xFF2196F3),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(24),
                                      topRight: Radius.circular(24),
                                    ),
                                  ),
                                  padding: EdgeInsets.all(isSmallScreen ? 44 : 24),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Bienvenido a AFA Andújar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 56 : 34,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(isSmallScreen ? 50 : 30),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Gestiona de forma segura y sencilla la recogida de personas con discapacidad y mayores. Realiza el seguimiento en tiempo real mediante mapas interactivos.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 36 : 22,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 50 : 30),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          return constraints.maxWidth < 800
                                              ? Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    _gradientButton(
                                                      context,
                                                      'Registrarse',
                                                      PathUrlAfa().pathRegister,
                                                      isLarge: isSmallScreen,
                                                    ),
                                                    SizedBox(height: isSmallScreen ? 30 : 15),
                                                    _gradientButton(
                                                      context,
                                                      'Iniciar sesión',
                                                      PathUrlAfa().pathLogin,
                                                      isLarge: isSmallScreen,
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  children: [
                                                    Expanded(
                                                      child: _gradientButton(
                                                        context,
                                                        'Registrarse',
                                                        PathUrlAfa().pathRegister,
                                                        isLarge: false,
                                                      ),
                                                    ),
                                                    SizedBox(width: 20),
                                                    Expanded(
                                                      child: _gradientButton(
                                                        context,
                                                        'Iniciar sesión',
                                                        PathUrlAfa().pathLogin,
                                                        isLarge: false,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: isSmallScreen ? 90 : 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black54],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '© 2025 AFA Andújar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 18 : 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _gradientButton(
      BuildContext context, String text, String route, {required bool isLarge}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF063970),
            Color(0xFF2196F3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => context.go(route),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 140 : 70,
            vertical: isLarge ? 44 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: Size(0, isLarge ? 90 : 60),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.hovered)) {
              return Colors.white.withOpacity(0.2);
            }
            return null;
          }),
        ),
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: Colors.white,
            fontSize: isLarge ? 34 : 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
