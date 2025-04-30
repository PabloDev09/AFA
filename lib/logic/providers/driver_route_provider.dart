import 'dart:async';
import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/providers/notification_provider.dart';

class DriverRouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();
    late NotificationProvider _notificationProvider;

  DriverRouteProvider(this._notificationProvider);

  /// Llamar desde el ProxyProvider para actualizar la referencia:
  void updateNotificationProvider(NotificationProvider newProvider) {
    _notificationProvider = newProvider;
  }


  List<RouteUser> pendingUsers = [];
  
  bool isRouteActive = false;
  bool isLoading = false;
  
  Timer? _conditionTimer;

  Future<void> startRoute() async {
    isRouteActive = true;
    await _routeService.createRoute();
    pendingUsers = await _routeService.getUsersToPickUp();
    print("Usuarios pendientes: ${pendingUsers.length}"); // 🔍

    notifyListeners();
    _notificationProvider.addNotification("Ruta iniciada");
  }

  Future<void> resumeRoute() async {
    isRouteActive = true;
    pendingUsers = await _routeService.getUsersToPickUp();
    print("Usuarios pendientes: ${pendingUsers.length}"); // 🔍

    notifyListeners();
    _notificationProvider.addNotification("Ruta reanudada");
  }

  Future<bool> canResumeRoute() async {
    isLoading = true;
    bool canContinue = await _routeService.canContinueRouteCollection();
    isLoading = canContinue;
    notifyListeners();
    return canContinue;
  }

  Future<void> stopRoute() async {
    isRouteActive = false;
    await _routeService.deleteRoute();
    pendingUsers.clear();
    notifyListeners();
    _notificationProvider.addNotification("Ruta finalizada");
  }

  Future<void> pickUpUser(String username) async {
    await _routeService.pickUpUser(username);
    _notificationProvider.addNotification("Se va a recoger a $username");
    _updatePendingUsers();
  }

  Future<void> cancelPickUpUser(String username) async {
    await _routeService.cancelPickUpUser(username);
    _notificationProvider.addNotification("Se canceló la recogida de $username");
    _updatePendingUsers();
  }

  Future<void> markUserAsCollected(String username) async {
    await _routeService.deleteUser(username);
    _notificationProvider.addNotification("Se recogió a $username");
    _updatePendingUsers();
  }

  Future<void> _updatePendingUsers() async {
    pendingUsers = await _routeService.getUsersToPickUp();
    notifyListeners();
  }

  @override
  void dispose() {
    _conditionTimer?.cancel();
    super.dispose();
  }
}
