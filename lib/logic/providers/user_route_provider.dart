import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';

class UserRouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();

  Future<void> cancelCollection(String username) async 
  {
    _routeService.deleteUser(username);
    notifyListeners();
  }
}
