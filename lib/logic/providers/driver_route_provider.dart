import 'dart:async';
import 'package:afa/logic/models/route_driver.dart';
import 'package:afa/logic/services/driver_route_service.dart';
import 'package:afa/utils.dart';
import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
        await _updateRouteDriver(routeDriver.username);
        await _routeService.updateAllDistances(
          driverLocation!,
          routeDriver.numRoute,
        );
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
        _notificationProvider.addNotification("Ruta iniciada.", false);
        await startListening();
      } else {
        _notificationProvider.addNotification(
          "Ya existe una ruta activa con ese número.",
          true,
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resumeRoute() async {
    await setDriverLocation();
    if (driverLocation == null || routeDriver.username.isEmpty) {
      _notificationProvider.addNotification(
        "No hay ruta para reanudar o ubicación no disponible.",
        true,
      );
      return;
    }

    isLoading = true;
    notifyListeners();
    try {
      await _updateRouteDriver(routeDriver.username);
      await _routeService.updateAllDistances(
        driverLocation!,
        routeDriver.numRoute,
      );
      await _getAllUsers(routeDriver.numRoute);
      _notificationProvider.addNotification("Ruta reanudada.", false);
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
      // Solo una llamada a Firestore para obtener driver
      final driver = await _driverRouteService.getDriverByUsername(username);
      if (driver == null) return false;

      routeDriver = driver;
      return await _routeService.canContinueRoute(routeDriver.numRoute);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> stopRoute() async {
    await _routeService.deleteRoute(routeDriver.numRoute);
    await _driverRouteService.removeDriverFromRoute(routeDriver.username);
    await _clearAllUsers();
    await stopListening();
    _notificationProvider.addNotification("Ruta finalizada.", false);
    notifyListeners();
  }

  Future<void> pickUpUser(String username, int numPick) async {
    await _routeService.pickUpUser(username, routeDriver.numRoute, numPick);
    _notificationProvider.addNotification("Recogiendo a $username.", false);
    await _getAllUsers(routeDriver.numRoute);
    notifyListeners();
  }

  Future<void> cancelPickUpUser(String username) async {
    await _routeService.cancelPickUpUser(username, routeDriver.numRoute);
    _notificationProvider.addNotification(
      "Recogida de $username cancelada.",
      false,
    );
    await _getAllUsers(routeDriver.numRoute);
    notifyListeners();
  }

  Future<void> markUserAsCollected(String username) async {
    await _routeService.markUserAsCollected(username, routeDriver.numRoute);
    _notificationProvider.addNotification("$username ha sido recogido.", false);
    await _getAllUsers(routeDriver.numRoute);
    notifyListeners();
  }

  Future<void> markRouteHasProblem() async {
    await _driverRouteService.markProblem(routeDriver.username);
    _notificationProvider.addNotification(
      "Tu alerta de incidencia en la ruta ha sido registrada correctamente. ",
      true,
    );
    notifyListeners();
  }

  Future<void> clearRouteHasProblem() async {
    await _driverRouteService.clearProblem(routeDriver.username);
    _notificationProvider.addNotification(
      "Tu alerta de incidencia en la ruta ha sido resuelta correctamente. ",
      true,
    );
    notifyListeners();
  }

  Future<void> updateRoute() async {
    await setDriverLocation();
    isLoading = true;
    notifyListeners();
    try {
      if (driverLocation != null) {
        await _updateRouteDriver(routeDriver.username);
        await _routeService.updateAllDistances(
          driverLocation!,
          routeDriver.numRoute,
        );
        await _getAllUsers(routeDriver.numRoute);
        _notificationProvider.addNotification("Ruta actualizada.", false);
      } else {
        _notificationProvider.addNotification(
          "Ubicación del conductor no disponible.",
          true,
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
