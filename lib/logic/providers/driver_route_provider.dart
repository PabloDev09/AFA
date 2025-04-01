import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:afa/logic/models/route_user.dart';

class DriverRouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();
  List<RouteUser> pendingUsers = [];
  bool isRouteActive = false;
  bool isLoading = false;

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
    return isLoading = await _routeService.canContinueRouteCollection();
  }

  Future<void> stopRoute() async {
    isRouteActive = false;
    await _routeService.deleteRouteCollection();
    pendingUsers.clear();
    notifyListeners();
  }

  Future<void> pickUpUser(String username) async {
    await _routeService.pickUpUser(username);
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
}
