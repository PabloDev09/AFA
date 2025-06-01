import 'dart:async';
import 'dart:convert';
import 'package:afa/logic/models/route_driver.dart';
import 'package:afa/logic/services/driver_route_service.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:afa/utils.dart';
import 'package:flutter/material.dart';
import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DriverRouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();
  final DriverRouteService _driverRouteService = DriverRouteService();
  late NotificationProvider _notificationProvider;

  List<RouteUser> pendingUsers = [];
  List<RouteUser> cancelledUsers = [];
  List<RouteUser> collectedUsers = [];
  RouteDriver routeDriver = Utils().routeDriverNull;

  bool get isRouteActive => pendingUsers.isNotEmpty;
  bool isLoading = false;
  bool isUpdating = false;

  LatLng? driverLocation;
  Timer? _locationTimer;

  DriverRouteProvider(this._notificationProvider);

  void updateNotificationProvider(NotificationProvider newProvider) {
    _notificationProvider = newProvider;
  }

  Future<void> setDriverLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      driverLocation = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (e) {
      _notificationProvider.addNotification(
        "Error al obtener la ubicación del conductor.",
        true,
        false
      );
    }
  }

  Future<void> startListening() async {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      isUpdating = true;
      notifyListeners();
      await setDriverLocation();
      if (driverLocation != null) {
        await _driverRouteService.updateLocation(
          routeDriver.username,
          driverLocation!,
        );
        await _routeService.updateAllDistances(
          driverLocation!,
          routeDriver.numRoute,
        );
        await _updateRouteDriver(routeDriver.username);
        await _getAllUsers(routeDriver.numRoute);
      }

      isUpdating = false;
      notifyListeners();
    });
  }

  Future<void> stopListening() async {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> startRoute(String username, int numRoute) async {
    await setDriverLocation();
    if (driverLocation == null) {
      _notificationProvider.addNotification(
        "Ubicación del conductor no disponible.",
        true,
        false
      );
      return;
    }

    isLoading = true;
    notifyListeners();
    try {
      final created = await _routeService.createRoute(
        driverLocation!,
        username,
        numRoute,
      );
      if (created) {
        await _updateRouteDriver(username);
        await _getAllUsers(routeDriver.numRoute);
        _notificationProvider.addNotification("Ruta iniciada.", false, false);
        await startListening();
      } else {
        _notificationProvider.addNotification(
          "Ya existe una ruta activa con ese número.",
          true,
          false
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resumeRoute() async {
    await setDriverLocation();
    isLoading = true;
    if (driverLocation == null || routeDriver.username.isEmpty) {
      _notificationProvider.addNotification(
        "No hay ruta para reanudar o ubicación no disponible.",
        true,
        false
      );
      return;
    }
    notifyListeners();
    try {
      await _updateRouteDriver(routeDriver.username);
      await _routeService.updateAllDistances(
        driverLocation!,
        routeDriver.numRoute,
      );
      await _getAllUsers(routeDriver.numRoute);
      _notificationProvider.addNotification("Ruta reanudada.", false, false);
      await startListening();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> canResumeRoute(String username) async {
    isLoading = true;
    notifyListeners();
    try {
      final driver = await _driverRouteService.getDriverByUsername(username);
      routeDriver = driver!;
      return await _routeService.canContinueRoute(routeDriver.numRoute);
    } 
    finally 
    {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> stopRoute() async {
    await _routeService.deleteRoute(routeDriver.numRoute);
    await _driverRouteService.removeDriverFromRoute(routeDriver.username);
    await _clearAllUsers();
    await stopListening();
    _notificationProvider.addNotification("Ruta finalizada.", false, false);
    notifyListeners();
  }

  Future<void> pickUpUser(String username, int numPick) async {
    await _routeService.pickUpUser(username, routeDriver.numRoute, numPick);
    _notificationProvider.addNotification("Recogiendo a $username.", false, false);
    await _getAllUsers(routeDriver.numRoute);
    notifyListeners();
  }

  Future<void> cancelPickUpUser(String username) async {
    await _routeService.cancelPickUpUser(username, routeDriver.numRoute);
    _notificationProvider.addNotification(
      "Recogida de $username cancelada.",
      false,
      false
    );
    await _getAllUsers(routeDriver.numRoute);
    notifyListeners();
  }

  Future<void> markUserAsCollected(String username) async {
    await _routeService.markUserAsCollected(username, routeDriver.numRoute);
    _notificationProvider.addNotification("$username ha sido recogido.", false, false);
    await _getAllUsers(routeDriver.numRoute);
    notifyListeners();
  }

  Future<void> markRouteHasProblem() async {
    await _driverRouteService.markProblem(routeDriver.username);
    routeDriver.hasProblem = true;
    _notificationProvider.addNotification(
      "Tu alerta de incidencia en la ruta ha sido reportada. ",
      true,
      false
    );
    
    notifyListeners();
  }

  Future<void> clearRouteHasProblem() async {
    await _driverRouteService.clearProblem(routeDriver.username);
    routeDriver.hasProblem = false;
    _notificationProvider.addNotification(
      "Tu alerta de incidencia en la ruta ha sido resuelta. ",
      false,
      true
    );
    notifyListeners();
  }

  Future<void> updateRoute() async {
    await setDriverLocation();
    isLoading = true;
    notifyListeners();
    try {
      if (driverLocation != null) {
        await _driverRouteService.updateLocation(
          routeDriver.username,
          driverLocation!,
        );
        await _routeService.updateAllDistances(
          driverLocation!,
          routeDriver.numRoute,
        );
        await _updateRouteDriver(routeDriver.username);
        await _getAllUsers(routeDriver.numRoute);
        _notificationProvider.addNotification("Ruta actualizada.", false, false);
      } else {
        _notificationProvider.addNotification(
          "Ubicación del conductor no disponible.",
          true,
          false
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Set<Marker>> get markers async {
  try {
    final markerSet = <Marker>{};
    if (driverLocation != null) {
      markerSet.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverLocation!,
          infoWindow: const InfoWindow(title: 'Posicion actual'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
    // User being picked marker
    final pickingUser = pendingUsers.firstWhere(
      (u) => u.isBeingPicking,
      orElse: () => throw StateError('No hay usuario siendo recogido'),
    );

    LatLng userLocation = await _getUserLocation(pickingUser.address);
    if(userLocation.latitude == 0 && userLocation.longitude == 0) {
      throw Exception('No se pudo obtener la ubicación del usuario');
    }

    markerSet.add(
      Marker(
        markerId: MarkerId('user_${pickingUser.username}'),
        position: userLocation,
        infoWindow: InfoWindow(title: 'Parada de ${pickingUser.name}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    return markerSet;
  } catch (_) {
    return <Marker>{};
  }
}

  Future<LatLng> _getUserLocation(String address) async {
    try {
      String formattedAddress = Utils().formatAddressForSearch(address);
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$formattedAddress&format=json',
        ),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return LatLng(
            double.parse(data[0]['lat'] as String),
            double.parse(data[0]['lon'] as String),
          );
        }
      }
    } catch (e) {
      debugPrint("Error al obtener la ubicación del usuario: $e");
    }
    return const LatLng(0, 0); 
  }

  Future<void> _getAllUsers(int numRoute) async {
    pendingUsers = await _routeService.getUsersByStatus(
      numRoute: numRoute,
      filter: (u) => !u.isCollected && !u.isCancelled,
    );
    cancelledUsers = await _routeService.getUsersByStatus(
      numRoute: numRoute,
      filter: (u) => u.isCancelled,
    );
    collectedUsers = await _routeService.getUsersByStatus(
      numRoute: numRoute,
      filter: (u) => u.isCollected,
    );
    notifyListeners();
  }

  Future<void> _clearAllUsers() async {
    routeDriver = Utils().routeDriverNull;
    pendingUsers.clear();
    cancelledUsers.clear();
    collectedUsers.clear();
    notifyListeners();
  }

  Future<void> _updateRouteDriver(String username) async {
    final driver = await _driverRouteService.getDriverByUsername(username);
    if (driver != null) {
      routeDriver = driver;
    } else {
      routeDriver = Utils().routeDriverNull;
      _notificationProvider.addNotification(
        "No se pudo cargar la información del conductor.",
        true,
        false
      );
    }
    notifyListeners();
  }

  void clearRoutes() {
    _clearAllUsers();
    notifyListeners();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }
}
