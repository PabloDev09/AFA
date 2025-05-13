import 'dart:async';
import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverRouteProvider extends ChangeNotifier 
{
  final RouteService _routeService = RouteService();
  late NotificationProvider _notificationProvider;

  // Lista de usuarios de ruta
  List<RouteUser> pendingUsers = [];
  List<RouteUser> cancelledUsers = [];
  List<RouteUser> collectedUsers = [];

  bool get isRouteActive => pendingUsers.isNotEmpty;

  // Estado de carga para UI
  bool isLoading = false;
  bool isUpdating = false;

  // Ubicación actual del conductor
  LatLng? driverLocation;
  Timer? _locationTimer;

  DriverRouteProvider(this._notificationProvider);

  void updateNotificationProvider(NotificationProvider newProvider) 
  {
    _notificationProvider = newProvider;
  }

  /// Captura la ubicación una sola vez
  Future<void> setDriverLocation() async 
  {
    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    driverLocation = LatLng(pos.latitude, pos.longitude);
    notifyListeners();
  }

  /// Inicia la actualización periódica de ubicación y distancias
  Future<void> startUpdatingDriverLocation() async 
  {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (_) async 
    {
      isUpdating = true;
      notifyListeners();
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      driverLocation = LatLng(pos.latitude, pos.longitude);
      
      if (driverLocation != null) 
      {
        await _routeService.updateAllDistances(driverLocation!);
        _getAllUsers();
        isUpdating = false;
        notifyListeners();
      }
    });
  }

  /// Detiene la actualización periódica
  Future<void> stopUpdatingDriverLocation() async 
  {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> startRoute() async 
  {
    await setDriverLocation();
    if (driverLocation != null) 
    {
      isLoading = true;
      notifyListeners();
      await _routeService.createRoute(driverLocation!);
      _getAllUsers();
      _notificationProvider.addNotification("Ruta iniciada");
      await startUpdatingDriverLocation();
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resumeRoute() async 
  {
    await setDriverLocation();
    if (driverLocation != null) 
    {
      isLoading = true;
      notifyListeners();
      await _routeService.updateAllDistances(driverLocation!);
      _getAllUsers();
      _notificationProvider.addNotification("Ruta reanudada");
      isLoading = false;
      await startUpdatingDriverLocation();
      notifyListeners();
    }
  }

  Future<bool> canResumeRoute() async 
  {
    isLoading = true;
    notifyListeners();
    bool canContinue = await _routeService.canContinueRouteCollection();
    isLoading = false;
    notifyListeners();
    return canContinue;
  }

  Future<void> stopRoute() async 
  {
    await _routeService.deleteRoute();
    _clearAllUsers();
    await stopUpdatingDriverLocation();
    _notificationProvider.addNotification("Ruta finalizada");
    notifyListeners();
  }

  Future<void> pickUpUser(String username) async 
  {
    await _routeService.pickUpUser(username);
    _notificationProvider.addNotification("Se va a recoger a $username");
    _getAllUsers();
    notifyListeners();
  }

  Future<void> cancelPickUpUser(String username) async 
  {
    await _routeService.cancelPickUpUser(username);
    _notificationProvider.addNotification("Se canceló la recogida de $username");
    _getAllUsers();
    notifyListeners();
  }

  Future<void> markUserAsCollected(String username) async 
  {
    await _routeService.markUserAsCollected(username);
    _notificationProvider.addNotification("Se recogió a $username");
    _getAllUsers();
    notifyListeners();
  }

  Future<void> updateRoute() async 
  {
    isUpdating = true;
    notifyListeners();
    await _routeService.updateAllDistances(driverLocation!);
    _getAllUsers();
    isUpdating = false;
    _notificationProvider.addNotification("Ruta actualizada");
    notifyListeners();
  }

  Future<void> _getAllUsers() async 
  {
    pendingUsers = await _routeService.getUsersByStatus(filter: (user) => !user.isCollected && !user.isCancelled,);
    cancelledUsers = await _routeService.getUsersByStatus(filter: (user) => user.isCancelled,);
    collectedUsers = await _routeService.getUsersByStatus(filter: (user) => user.isCollected,);
    notifyListeners();
  }

    Future<void> _clearAllUsers() async 
  {
    pendingUsers.clear();
    cancelledUsers.clear();
    collectedUsers.clear();
    notifyListeners();
  }

  @override
  void dispose() 
  {
    _locationTimer?.cancel();
    super.dispose();
  }

  void clearRoutes() 
  {
    pendingUsers.clear();
    driverLocation = null;
    notifyListeners();
  }
}
