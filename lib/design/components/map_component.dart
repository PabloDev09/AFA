// IMPORTS
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';

class MapComponent extends StatefulWidget {
  final bool isDriver;
  final Color routeColor;

  const MapComponent({
    super.key,
    required this.isDriver,
    this.routeColor = Colors.blue,
  });

  @override
  _MapComponentState createState() => _MapComponentState();
}

class _MapComponentState extends State<MapComponent> {
  Set<Marker> markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _hasError = false;
  bool _markersReady = false;
  bool _mapReady = false;
  GoogleMapController? _mapController;
  LatLngBounds? _routeBounds;
  MarkerId? _driverMarkerId;
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _userIcon;

  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;

  @override
  void initState() {
    super.initState();
    _loadIcons().then((_) => _retryLoadMap());
  }

  Future<void> _loadIcons() async {
    _driverIcon = BitmapDescriptor.fromBytes(
      await _createBitmapFromIcon(Icons.directions_bus, Colors.blue),
    );
    _userIcon = BitmapDescriptor.fromBytes(
      await _createBitmapFromIcon(Icons.person_pin_circle, Colors.cyan),
    );
  }

  void _retryLoadMap() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _markersReady = false;
      _mapReady = false;
      markers.clear();
      _polylines.clear();
      _driverMarkerId = null;
      _routeBounds = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // 1) Obtener marcadores desde el provider (driver o user)
        final rawMarkers = widget.isDriver
            ? await Provider.of<DriverRouteProvider>(context, listen: false).markers
            : await Provider.of<UserRouteProvider>(context, listen: false).markers;

        // 2) Estilizar marcadores con iconos personalizados
        final styled = _styleMarkers(rawMarkers);

        if (!mounted) return;
        setState(() {
          markers = styled;
          _markersReady = true;
        });

        // 3) Calcular ruta y bounds
        await _drawRouteBetweenMarkers();

        if (_mapReady) {
          await _centerMap();
        }

        if (mounted) setState(() => _isLoading = false);
      } catch (e) {
        debugPrint('Error loading map: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cargar el mapa. Inténtalo de nuevo.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    });
  }

  Set<Marker> _styleMarkers(Set<Marker> input) {
    final styled = <Marker>{};
    for (var m in input) {
      final title = m.markerId.value;
      if (title.contains("driver") && _driverIcon != null) {
        _driverMarkerId = m.markerId;
        styled.add(
          m.copyWith(
            iconParam: _driverIcon,
            anchorParam: const Offset(0.5, 1.0),
          ),
        );
      } else if (_userIcon != null) {
        styled.add(
          m.copyWith(
            iconParam: _userIcon,
            anchorParam: const Offset(0.5, 1.0),
          ),
        );
      }
    }
    return styled;
  }

  Future<void> _drawRouteBetweenMarkers() async {
    if (markers.length < 2) return;
    final list = markers.toList();
    final start = list.first.position;
    final end = list.last.position;
    final points = await _getPolylinePoints(start, end);
    if (points.isEmpty) return;

    final polyline = Polyline(
      polylineId: const PolylineId("real_route"),
      color: widget.routeColor,
      width: 5,
      points: points,
    );

    // Calcular bounds
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (var p in points) {
      minLat = _min(minLat, p.latitude);
      maxLat = _max(maxLat, p.latitude);
      minLng = _min(minLng, p.longitude);
      maxLng = _max(maxLng, p.longitude);
    }
    _routeBounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    setState(() => _polylines = {polyline});
  }

  Future<List<LatLng>> _getPolylinePoints(LatLng origin, LatLng destination) async {
    const url = 'https://routes.googleapis.com/directions/v2:computeRoutes';
    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _googleApiKey,
      'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
    };
    final body = jsonEncode({
      'origin': {
        'location': {
          'latLng': {
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          },
        },
      },
      'destination': {
        'location': {
          'latLng': {
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          },
        },
      },
      'travelMode': 'DRIVE',
    });
    final response = await http.post(Uri.parse(url), headers: headers, body: body);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final encoded = json['routes'][0]['polyline']['encodedPolyline'] as String;
      final decoded = PolylinePoints().decodePolyline(encoded);
      return decoded.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } else {
      debugPrint('Route API error: ${response.statusCode}');
      return [];
    }
  }

  Future<void> _centerMap() async {
    if (_mapController == null || markers.isEmpty || _routeBounds == null) return;
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(_routeBounds!, 40),
      );
    } catch (_) {
      final centerLat = (_routeBounds!.southwest.latitude + _routeBounds!.northeast.latitude) / 2;
      final centerLng = (_routeBounds!.southwest.longitude + _routeBounds!.northeast.longitude) / 2;
      await _mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(LatLng(centerLat, centerLng), 14),
      );
    }
  }

  /// Centrar en la parada del usuario
  Future<void> _centerOnUser() async {
    if (_mapController == null || markers.isEmpty) return;
    final userMarker = markers.firstWhere(
      (m) => m.markerId.value.contains("user"),
      orElse: () => markers.first,
    );
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(userMarker.position, 15),
    );
  }

  /// Centrar en el conductor
  Future<void> _centerOnDriver() async {
    if (_mapController == null || _driverMarkerId == null) return;
    final driverMarker = markers.firstWhere(
      (m) => m.markerId == _driverMarkerId,
      orElse: () => markers.first,
    );
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(driverMarker.position, 15),
    );
  }

Future<Uint8List> _createBitmapFromIcon(IconData icon, Color color) async {
  const double size = 50;
  const double borderWidth = 2.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const center = Offset(size / 2, size / 2);
  const radius = (size / 2) - (borderWidth / 2); // Deja espacio para el borde

  // Fondo circular semitransparente
  final backgroundPaint = Paint()..color = color.withOpacity(0.2);
  canvas.drawCircle(center, radius, backgroundPaint);

  // Borde circular dentro del canvas
  final borderPaint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = borderWidth;
  canvas.drawCircle(center, radius, borderPaint);

  // Pintar el icono centrado
  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 30,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    ),
  );

  // Convertir a imagen
  final imgCanvas = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final byteData = await imgCanvas.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mapHeight = (size.height > size.width) ? size.height * 0.3 : size.height * 0.6;

    if (_isLoading) {
      return SizedBox(
        height: mapHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || markers.isEmpty) {
      return SizedBox(
        height: mapHeight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 80, color: Colors.blue),
              const SizedBox(height: 12),
              const Text(
                'Mapa no disponible',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _retryLoadMap,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: mapHeight,
      child: Stack(
        children: [
          // GoogleMap sin controles predeterminados y con límite de cámara
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(target: LatLng(0, 0), zoom: 16),
                onMapCreated: (controller) async {
                  _mapController = controller;
                  _mapReady = true;
                  if (_markersReady) {
                    await _centerMap();
                  }
                },
                markers: markers,
                polylines: _polylines,
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                tiltGesturesEnabled: false,
                trafficEnabled: false,
                buildingsEnabled: false,
                indoorViewEnabled: false,
                rotateGesturesEnabled: false,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                cameraTargetBounds: _routeBounds != null
                    ? CameraTargetBounds(_routeBounds!)
                    : CameraTargetBounds(
                        LatLngBounds(
                          southwest: LatLng(-90, -180),
                          northeast: LatLng(90, 180),
                        ),
                      ),
              ),
            ),
          ),

          // Botones de recenter: a la derecha inferior
          Positioned(
            bottom: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_driverMarkerId != null)
                  _buildCircleButton(
                    icon: Icons.directions_bus,
                    tooltip: 'Seguir al conductor',
                    onPressed: _centerOnDriver,
                  ),
                const SizedBox(height: 8),
                _buildCircleButton(
                  icon: Icons.person_pin_circle,
                  tooltip: 'Ir a tu parada',
                  onPressed: _centerOnUser,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Botón circular con fondo azul y icono negro
  Widget _buildCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      shape: const CircleBorder(),
      elevation: 4,
      color: Colors.blue,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 24, color: Colors.white),
        ),
      ),
    );
  }
}

// Helpers
T _max<T extends num>(T a, T b) => a > b ? a : b;
T _min<T extends num>(T a, T b) => a < b ? a : b;
