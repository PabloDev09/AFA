import 'package:afa/logic/controllers/afa_gif_controller.dart';
import 'package:afa/logic/providers/bus_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoadingNoChildScreen extends StatefulWidget {
  /// Si se define [destinationRoute] se asume que se trata de un cambio de pantalla
  /// y se navegara a dicha ruta luego de 3 segundos.
  /// Si se está esperando obtener datos, se deja pasar [destinationRoute] como null
  /// (o se puede forzar [waitForData] a true) para que el widget se muestre indefinidamente.
  final String? destinationRoute;
  
  /// Si es `true`, se muestra el loader de forma indefinida (por ejemplo, mientras se esperan datos).
  /// De forma predeterminada es false.
  final bool waitForData;
  
  const LoadingNoChildScreen({
    super.key,
    this.destinationRoute,
    this.waitForData = false,
  });

  @override
  State<LoadingNoChildScreen> createState() => _LoadingNoChildScreenState();
}

class _LoadingNoChildScreenState extends State<LoadingNoChildScreen>
    with TickerProviderStateMixin {
  // Controlador para el GIF (puede usarse para manejar sprites, tal como en el widget anterior).
  late AfaGifController _gifController;
  // Se asume que el sprite sheet cuenta con 1 frame (puedes modificar este valor según tus necesidades)
  final int frameCount = 1;

  @override
  void initState() {
    super.initState();

    // Inicializamos el controlador para el GIF
    _gifController = AfaGifController(
      vsync: this,
      frameCount: frameCount,
      fps: 30,
    );

    // Iniciamos la animación del autobús de forma continua.
    final busProvider = Provider.of<BusProvider>(context, listen: false);
    busProvider.startAnimation(this);

    // Si se pasó una ruta destino y no se está esperando datos,
    // se programa una espera de 3 segundos para navegar a la siguiente pantalla.
    if (widget.destinationRoute != null && !widget.waitForData) {
      Future.delayed(const Duration(seconds: 3), () {
        // Se detiene la animación del autobús antes de navegar
        busProvider.stopAnimation();
        if (mounted) {
          // Si lo usas con Navigator:
          Navigator.pushReplacementNamed(context, widget.destinationRoute!);
          
          // Si prefieres usar otro método de navegación (por ejemplo, go_router),
          // reemplaza la línea anterior por la lógica correspondiente.
        }
      });
    }
  }

  @override
  void dispose() {
    _gifController.animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Se utiliza un Scaffold para cubrir toda la pantalla,
    // con un fondo degradado similar al widget original.
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF063970), Color(0xFF66B3FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Logo e indicador de carga centrados.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
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
                      width: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 6,
                  ),
                ],
              ),
            ),
            // Animación del autobús. Este se mueve continuamente de izquierda a derecha y
            // al salir por la derecha vuelve a aparecer por la izquierda.
            Consumer<BusProvider>(
              builder: (context, busProvider, child) {
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                // El ancho del autobús será el menor entre 25% del ancho y 30% del alto.
                final busWidth =
                    (screenWidth * 0.25).clamp(0.0, screenHeight * 0.3);
                // Se calcula la posición horizontal en función de un valor de progresión.
                // El valor [busProgress] se debe actualizar de forma cíclica (debe ir de 0 a 1 y reiniciarse).
                final xPos =
                    -busWidth + busProvider.busProgress * (screenWidth + busWidth);

                return Positioned(
                  bottom: 0, // Siempre pegado abajo.
                  left: xPos,
                  child: SizedBox(
                    width: busWidth,
                    height: busWidth,
                    child: AnimatedBuilder(
                      animation: _gifController.animationController,
                      builder: (context, child) {
                        final spriteSheetWidth = busWidth * frameCount;
                        return ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1 / frameCount,
                            child: Image.asset(
                              'assets/images/autobus-unscreen.gif',
                              width: spriteSheetWidth,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
