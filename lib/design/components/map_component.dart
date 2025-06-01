// IMPORTS
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:image/image.dart' as img;

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
  GoogleMapController? _mapController;

  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY']!;
  final List<BitmapDescriptor> _driverFrames = [];
  int _currentDriverFrameIndex = 0;
  Timer? _animationTimer;
  MarkerId? _driverMarkerId;

  @override
  void initState() {
    super.initState();
    _retryLoadMap();
  }

  void _retryLoadMap() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _loadDriverFramesFromGif();

        final rawMarkers = widget.isDriver
            ? await Provider.of<DriverRouteProvider>(context, listen: false).markers
            : await Provider.of<UserRouteProvider>(context, listen: false).markers;

        final styledMarkers = await _styleMarkers(rawMarkers);

        if (!mounted) return;

        setState(() {
          markers = styledMarkers;
        });

        await Future.delayed(const Duration(milliseconds: 600));
        await _fitMarkersInView();
        await _drawRouteBetweenMarkers();

        if (mounted) {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        debugPrint('Error loading map: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });

          // Mostrar SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cargar el mapa. Inténtalo de nuevo.'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _animationTimer?.cancel();
  }

  Future<void> _loadDriverFramesFromGif() async {
    final byteData = await rootBundle.load('assets/images/autobus-unscreen.gif');
    final gifBytes = byteData.buffer.asUint8List();
    final gif = img.GifDecoder().decode(gifBytes);
    if (gif == null) throw Exception('GIF decoding failed');

    for (final frame in gif.frames) {
      final pngBytes = img.PngEncoder().encode(frame);
      final descriptor = BitmapDescriptor.fromBytes(Uint8List.fromList(pngBytes));
      _driverFrames.add(descriptor);
    }
  }

  Future<void> _drawRouteBetweenMarkers() async {
    if (markers.length < 2) throw Exception('Insufficient markers');

    final markerList = markers.toList();
    final start = markerList.first.position;
    final end = markerList.last.position;
    final routePoints = await _getPolylinePoints(start, end);

    if (routePoints.isEmpty) throw Exception('Route points empty');

    final polyline = Polyline(
      polylineId: const PolylineId("real_route"),
      color: widget.routeColor,
      width: 5,
      points: routePoints,
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
      final encodedPolyline = json['routes'][0]['polyline']['encodedPolyline'] as String;
      final decodedPoints = PolylinePoints().decodePolyline(encodedPolyline);
      return decodedPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } else {
      throw Exception('Route API error: ${response.statusCode}');
    }
  }

  Future<void> _fitMarkersInView() async {
    if (_mapController == null || markers.isEmpty) return;

    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (var marker in markers) {
      minLat = min(minLat, marker.position.latitude);
      maxLat = max(maxLat, marker.position.latitude);
      minLng = min(minLng, marker.position.longitude);
      maxLng = max(maxLng, marker.position.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    try {
      await _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 40));
    } catch (_) {
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      await _mapController!.moveCamera(
        CameraUpdate.newLatLngZoom(LatLng(centerLat, centerLng), 14),
      );
    }
  }

  Future<Set<Marker>> _styleMarkers(Set<Marker> inputMarkers) async {
    Set<Marker> styledMarkers = {};

    for (var marker in inputMarkers) {
      final title = marker.markerId.value;

      if (title.contains("driver")) {
        _driverMarkerId = marker.markerId;
        final firstFrame = _driverFrames.isNotEmpty
            ? _driverFrames[0]
            : BitmapDescriptor.defaultMarker;

        styledMarkers.add(marker.copyWith(iconParam: firstFrame));

        if (_animationTimer == null && _driverFrames.length > 1) {
          _startDriverAnimation();
        }
      } else {
        final iconBitmap = await _createCustomMarkerBitmap(
          Icons.location_on,
          title.contains("user") ? Colors.indigo.shade700 : Colors.blue.shade400,
        );
        styledMarkers.add(marker.copyWith(iconParam: BitmapDescriptor.fromBytes(iconBitmap)));
      }
    }

    return styledMarkers;
  }

  void _startDriverAnimation() {
    const int frameDurationMs = 200;
    _animationTimer = Timer.periodic(
      const Duration(milliseconds: frameDurationMs),
      (timer) {
        if (!mounted || _driverFrames.isEmpty || _driverMarkerId == null) {
          timer.cancel();
          return;
        }

        _currentDriverFrameIndex =
            (_currentDriverFrameIndex + 1) % _driverFrames.length;
        final nextFrame = _driverFrames[_currentDriverFrameIndex];

        if (!markers.any((m) => m.markerId == _driverMarkerId)) {
          timer.cancel();
          return;
        }

        final oldMarker = markers.firstWhere((m) => m.markerId == _driverMarkerId);
        final newMarker = oldMarker.copyWith(iconParam: nextFrame);

        setState(() {
          markers.removeWhere((m) => m.markerId == _driverMarkerId);
          markers.add(newMarker);
        });
      },
    );
  }

  Future<Uint8List> _createCustomMarkerBitmap(IconData iconData, Color color) async {
    const double size = 90;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2, backgroundPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 40,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;
    final mapHeight = isPortrait ? screenSize.height * 0.3 : screenSize.height * 0.6;

    if (_isLoading) {
      return SizedBox(
        height: mapHeight,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError || markers.isEmpty) {
      return SizedBox(
        height: mapHeight,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 80,
                      color: Colors.indigo,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mapa no disponible',
                  style: TextStyle(
                    color: Colors.indigo,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
                    backgroundColor: Colors.indigo.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: mapHeight,
      child: Container(
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
            onMapCreated: (c) => _mapController = c,
            markers: markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            tiltGesturesEnabled: false,
            zoomControlsEnabled: false,
            trafficEnabled: false,
            buildingsEnabled: false,
            indoorViewEnabled: false,
          ),
        ),
      ),
    );
  }
}

// Helpers
T max<T extends num>(T a, T b) => a > b ? a : b;
T min<T extends num>(T a, T b) => a < b ? a : b;
