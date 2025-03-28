import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:afa/logic/models/route_user.dart';

class DriverRouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();
  List<RouteUser> usersToPickUp = [];
  bool rutaIniciada = false;
  bool isLoading = false;

  Future<void> startRoute() async 
  {
    rutaIniciada = true;
    await _routeService.createRouteCollection();
    usersToPickUp = await _routeService.getUsersToPickUp();
    notifyListeners();
  }

  Future<void> continueRoute() async 
  {
    rutaIniciada = true;
    usersToPickUp = await _routeService.getUsersToPickUp();
    notifyListeners();
  }

  Future<bool> canContinueRoute() async 
  {
    isLoading = true;
    return isLoading = await _routeService.canContinueRouteCollection();
  }

  Future<void> stopRoute() async 
  {
    rutaIniciada = false;
    await _routeService.deleteRouteCollection();
    usersToPickUp.clear();
    notifyListeners();
  }

  Future<void> pickUpUser(String username) async 
  {
    await _routeService.pickUpUser(username);
    _fetchRouteUsers();
  }

  Future<void> cancelPickUpUser(String username) async 
  {
    await _routeService.cancelPickUpUser(username);
    _fetchRouteUsers();
  }

  Future<void> collectedUser(String username) async 
  {
    await _routeService.deleteUser(username);
    _fetchRouteUsers();
  }

  Future<void> _fetchRouteUsers() async 
  {
    usersToPickUp = await _routeService.getUsersToPickUp();
    notifyListeners();
  }
}
