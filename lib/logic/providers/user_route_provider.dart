import 'dart:async';
import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';

class UserRouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();
  bool isPickupScheduled = true;
  final List<String> notifications = [];
  Timer? _conditionTimer;
  bool _previousCondition = false; 

  UserRouteProvider();

  Future<void> cancelPickup() async {
    isPickupScheduled = false;
    notifyListeners();
  }

  Future<void> resumePickup() async {
    isPickupScheduled = true;
    notifyListeners();
  }

  void addNotification(String message) {
    notifications.insert(0, message);
    notifyListeners();
  }

  Future<void> cancelUserPickup(String username) async {
    await _routeService.deleteUser(username);
    notifyListeners();
  }

  void startListening(String username) {
    _conditionTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      bool condition = await _routeService.isGoingToPickUpUser(username);

      if (condition && !_previousCondition) {
        _previousCondition = condition;
        addNotification("¡Preparate! ¡El conductor va a recogerte!");
      } 
      else if (!condition && _previousCondition) {
        _previousCondition = condition;
        addNotification("¡El conductor ha cancelado la recogida!");
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _conditionTimer?.cancel();
    super.dispose();
  }
}
