import 'dart:async';
import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:afa/logic/services/cancel_route_service.dart';
import 'package:intl/intl.dart';

class UserRouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();
  final CancelRouteService _cancelRouteService = CancelRouteService();
  final List<String> notifications = [];
  
  bool isPickupScheduled = true;
  Timer? _conditionTimer;
  bool _previousCondition = false; 

  Future<void> cancelPickupForDate(String username, DateTime cancelDate) async 
  {
    await _cancelRouteService.cancelRoute(username, cancelDate);
    isPickupScheduled = false;
    addNotification("Se canceló la recogida para la fecha ${DateFormat('dd/MM/yyyy').format(cancelDate.toLocal())}.");
    notifyListeners();
  }

  Future<void> removeCancelPickup(String username, DateTime removeCancelDate) async 
  {
    await _cancelRouteService.removeCancelRoute(username, removeCancelDate);
    isPickupScheduled = true;
    addNotification("Se removió la cancelación de la recogida.");
    notifyListeners();
  }

  void startListening(String username) 
  {
    _conditionTimer = Timer.periodic(const Duration(seconds: 1), (timer) async 
    {
      bool condition = await _routeService.isGoingToPickUpUser(username);
      if (condition && !_previousCondition) 
      {
        _previousCondition = condition;
        addNotification("¡Preparate! ¡El conductor va a recogerte!");
      } else if (!condition && _previousCondition) 
      {
        _previousCondition = condition;
        addNotification("¡El conductor ha cancelado la recogida!");
      }
      notifyListeners();
    });
  }

  void addNotification(String message) 
  {
    notifications.insert(0, message);
    notifyListeners();
  }

  @override
  void dispose() 
  {
    _conditionTimer?.cancel();
    super.dispose();
  }
}
