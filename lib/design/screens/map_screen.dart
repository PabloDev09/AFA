import 'package:afa/design/components/side_bar_menu.dart';
import 'package:afa/logic/providers/auth_user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  LatLng _currentLocation = const LatLng(38.0358053, -4.0247146);
  LatLng _driverLocation = const LatLng(38.0386, -3.7746);
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    

  WidgetsBinding.instance.addPostFrameCallback((_) async 
   {
    await Provider.of<AuthUserProvider>(context, listen: false).loadUser();
    await _determinePosition();
  });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation));
  }

  void _moveDriver() {
    setState(() {
      _driverLocation = LatLng(
        _driverLocation.latitude + 0.001,
        _driverLocation.longitude + 0.001,
      );
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(_driverLocation));
  }

  void _calculateDistance() {
    setState(() {});
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      drawer: const Drawer( child: SidebarMenu(selectedIndex: 1),),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white), 
          tooltip: 'Abrir menú', 
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
        actions: [
          _buildMenuButton("Centrar", Icons.my_location, _determinePosition),
          _buildMenuButton("Conductor", Icons.directions_car, _moveDriver),
          _buildMenuButton("Distancia", Icons.location_on, _calculateDistance),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentLocation, zoom: 14),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            tiltGesturesEnabled: true,
            compassEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            markers: {
              Marker(
                markerId: const MarkerId("current"),
                position: _currentLocation,
                infoWindow: const InfoWindow(title: "Tu parada"),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              ),
              Marker(
                markerId: const MarkerId("driver"),
                position: _driverLocation,
                infoWindow: const InfoWindow(title: "Conductor"),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
          ),
          // Footer con fondo degradado (se mantiene en la parte inferior)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
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
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '© 2025 AFA Andújar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(String label, IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF063970), Color(0xFF66B3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: FittedBox(
          fit: BoxFit.scaleDown,
          child: Icon(icon, color: Colors.white),
        ),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}
