import 'dart:async';
import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/providers/notification_provider.dart';

class DriverRouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();
  final NotificationProvider notificationProvider;

  // Constructor que recibe NotificationProvider como dependencia
  DriverRouteProvider(this.notificationProvider);

  List<RouteUser> pendingUsers = [];
  
  bool isRouteActive = false;
  bool isLoading = false;
  
  Timer? _conditionTimer;

  Future<void> startRoute() async {
    isRouteActive = true;
    await _routeService.createRoute();
    pendingUsers = await _routeService.getUsersToPickUp();
    notifyListeners();
    notificationProvider.addNotification("Ruta iniciada");
  }

  Future<void> resumeRoute() async {
    isRouteActive = true;
    pendingUsers = await _routeService.getUsersToPickUp();
    notifyListeners();
    notificationProvider.addNotification("Ruta reanudada");
  }

  Future<bool> canResumeRoute() async {
    isLoading = true;
    bool canContinue = await _routeService.canContinueRouteCollection();
    isLoading = canContinue;
    return canContinue;
  }

  Future<void> stopRoute() async {
    isRouteActive = false;
    await _routeService.deleteRoute();
    pendingUsers.clear();
    notifyListeners();
    notificationProvider.addNotification("Ruta finalizada");
  }

  Future<void> pickUpUser(String username) async {
    await _routeService.pickUpUser(username);
    notificationProvider.addNotification("Se va a recoger a $username");
    _updatePendingUsers();
  }

  Future<void> cancelPickUpUser(String username) async {
    await _routeService.cancelPickUpUser(username);
    notificationProvider.addNotification("Se canceló la recogida de $username");
    _updatePendingUsers();
  }

  Future<void> markUserAsCollected(String username) async {
    await _routeService.deleteUser(username);
    notificationProvider.addNotification("Se recogió a $username");
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
