import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';

class UserRouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();

  bool _pickupScheduled = true;
  final List<String> _notifications = [];

  bool get pickupScheduled => _pickupScheduled;
  List<String> get notifications => _notifications;

  Future<void> cancelPickup() async {
    _pickupScheduled = false;
    notifyListeners();
  }

  Future<void> resumePickup() async {
    _pickupScheduled = true;
    notifyListeners();
  }

  void addNotification(String message) {
    _notifications.insert(0, message);
    notifyListeners();
  }
  Future<void> cancelCollection(String username) async 
  {
    _routeService.deleteUser(username);
    notifyListeners();
  }
}
