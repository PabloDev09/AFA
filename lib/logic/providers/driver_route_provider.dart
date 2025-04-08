import 'dart:async';
import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:afa/logic/models/route_user.dart';

class DriverRouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();
  List<RouteUser> pendingUsers = [];
  bool isRouteActive = false;
  bool isLoading = false;
  final List<String> notifications = [];
  Timer? _conditionTimer;

  Future<void> startRoute() async {
    isRouteActive = true;
    await _routeService.createRouteCollection();
    pendingUsers = await _routeService.getUsersToPickUp();
    notifyListeners();
  }

  Future<void> resumeRoute() async {
    isRouteActive = true;
    pendingUsers = await _routeService.getUsersToPickUp();
    notifyListeners();
  }

  Future<bool> canResumeRoute() async {
    isLoading = true;
    bool canContinue = await _routeService.canContinueRouteCollection();
    isLoading = canContinue;
    return canContinue;
  }

  Future<void> stopRoute() async {
    isRouteActive = false;
    await _routeService.deleteRouteCollection();
    pendingUsers.clear();
    notifyListeners();
  }

  Future<void> pickUpUser(String username) async {
    await _routeService.pickUpUser(username);
    addNotification("Se recogió a $username");
    _updatePendingUsers();
  }

  Future<void> cancelPickUp(String username) async {
    await _routeService.cancelPickUpUser(username);
    _updatePendingUsers();
  }

  Future<void> markUserAsCollected(String username) async {
    await _routeService.deleteUser(username);
    _updatePendingUsers();
  }

  Future<void> _updatePendingUsers() async {
    pendingUsers = await _routeService.getUsersToPickUp();
    notifyListeners();
  }

  void addNotification(String message) 
  {
    notifications.insert(0, message);
    notifyListeners();
  }

  @override
  void dispose() {
    _conditionTimer?.cancel();
    super.dispose();
  }
}
