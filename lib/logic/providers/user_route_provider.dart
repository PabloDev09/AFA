import 'dart:async';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:afa/logic/services/cancel_route_service.dart';
import 'package:intl/intl.dart';

class UserRouteProvider extends ChangeNotifier 
{
  final RouteService _routeService = RouteService();
  final CancelRouteService _cancelRouteService = CancelRouteService();
 late NotificationProvider _notificationProvider;

  UserRouteProvider(this._notificationProvider);

  void updateNotificationProvider(NotificationProvider newProvider) {
    _notificationProvider = newProvider;
  }
  List<DateTime> cancelDates = [];
  
  Timer? _conditionTimer;
  bool previousIsGoingToPickUpUser = false; 
  bool previousIsNearToPickUpUser = false; 

  Future<void> getCancelDates(String username) async 
  {
    cancelDates = await _cancelRouteService.getCancelDates(username);
    notifyListeners();
  }

  Future<void> cancelPickupForDate(String username, DateTime cancelDate) async 
  {
    await _cancelRouteService.cancelRoute(username, cancelDate);
    _notificationProvider.addNotification("Se canceló la recogida para la fecha ${DateFormat('dd/MM/yyyy').format(cancelDate.toLocal())}.");
    getCancelDates(username);
    notifyListeners();
  }

  Future<void> removeCancelPickup(String username, DateTime removeCancelDate) async 
  {
    await _cancelRouteService.removeCancelRoute(username, removeCancelDate);
    _notificationProvider.addNotification("Se removió la cancelación de la recogida para la fecha ${DateFormat('dd/MM/yyyy').format(removeCancelDate.toLocal())}.");
    getCancelDates(username);
    notifyListeners();
  }

  void startListening(String username) 
  {
    _conditionTimer = Timer.periodic(const Duration(seconds: 1), (timer) async 
    {
      bool isGoingToPickUpUser = await _routeService.isGoingToPickUpUser(username);
      if (isGoingToPickUpUser && !previousIsGoingToPickUpUser) 
      {
        previousIsGoingToPickUpUser = isGoingToPickUpUser;
        _notificationProvider.addNotification("¡Preparate! ¡El conductor va a recogerte!");
      }

      bool isNearToPickUpUser = await _routeService.isNearToPickUpUser(username);
      if (isNearToPickUpUser && !previousIsNearToPickUpUser) 
      {
        previousIsNearToPickUpUser = isNearToPickUpUser;
        _notificationProvider.addNotification("¡El conductor está a 5 minutos! ¡Ve al punto de recogida!");
      }

      if (!isGoingToPickUpUser && previousIsGoingToPickUpUser) 
      {
        previousIsGoingToPickUpUser = isGoingToPickUpUser;
        _notificationProvider.addNotification("¡El conductor ha cancelado la recogida!");
      }
      notifyListeners();
    });
  }

  Future<void> cancelCurrentPickup(String username) async 
  {
    await _routeService.cancelCurrentPickup(username);
    _notificationProvider.addNotification("Has cancelado tu recogida actual.");
    notifyListeners();
  }

  Future<bool> checkIfUserIsBeingPicked(String username) async 
  {
    return await _routeService.isGoingToPickUpUser(username);
  }


  @override
  void dispose() 
  {
    _conditionTimer?.cancel();
    super.dispose();
  }
}
