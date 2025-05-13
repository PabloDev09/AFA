import 'dart:async';
import 'package:afa/logic/models/route_user.dart';
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

  void updateNotificationProvider(NotificationProvider newProvider) 
  {
    _notificationProvider = newProvider;
  }
  
  late RouteUser routeUser;

  bool isOtherBeingPicked = false;
  bool isRouteActive = false;
  bool isLoading = false;
  bool isUpdating = false;

  List<DateTime> cancelDates = [];
  Timer? _conditionTimer;
  bool previousIsGoingToPickUpUser = false; 
  bool previousIsNearToPickUpUser = false; 

  Future<void> loadRouteUser(String? username) async 
  {
    routeUser = (await _routeService.loadRouteUser(username))!;
    isOtherBeingPicked = await _routeService.isAnotherUserBeingPicked(routeUser.username);
    notifyListeners();
  }

  Future<bool> checkIfRouteActive(String? username) async 
  {
    isUpdating = true;
    notifyListeners();
    if (username == null) return false;
    bool auxIsRouteActive = await _routeService.userExistsInRoute(username);
    if(!isRouteActive && auxIsRouteActive)
    {
      isLoading = true;
      notifyListeners();
      await loadRouteUser(username);
      await startListening();
      _notificationProvider.addNotification("La ruta está activa.");
      isLoading = false;
      notifyListeners();
    }
    else if(isRouteActive && !auxIsRouteActive)
    {
      isLoading = true;
      notifyListeners();  
      _notificationProvider.addNotification("La ruta ha finalizado.");
      await stopListening();
      clearRoutes();
      isLoading = false;
      notifyListeners();
    }
  
    isRouteActive = auxIsRouteActive;
    isUpdating = false;
    notifyListeners();
    return isRouteActive;
  }

  Future<void> getCancelDates(String username) async 
  {
    cancelDates = await _cancelRouteService.getCancelDatesByUser(username);
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
    _notificationProvider.addNotification("Se reanudó la recogida para la fecha ${DateFormat('dd/MM/yyyy').format(removeCancelDate.toLocal())}.");
    getCancelDates(username);
    notifyListeners();
  }

  Future<void> startListening() 
  async 
  {
    _conditionTimer = Timer.periodic(const Duration(seconds: 10), (timer) async 
    {
      bool auxIsOtherBeingPicked = await _routeService.isAnotherUserBeingPicked(routeUser.username);
      bool isGoingToPickUpUser = await _routeService.isGoingToPickUpUser(routeUser.username);
      if (!isOtherBeingPicked && auxIsOtherBeingPicked) 
      {
        isOtherBeingPicked = auxIsOtherBeingPicked;
        _notificationProvider.addNotification("¡El conductor está recogiendo a otro usuario!");
      }
      if (isGoingToPickUpUser && !previousIsGoingToPickUpUser) 
      {
        previousIsGoingToPickUpUser = isGoingToPickUpUser;
        _notificationProvider.addNotification("¡Preparate! ¡El conductor va a recogerte!");
      }

      bool isNearToPickUpUser = await _routeService.isNearToPickUpUser(routeUser.username);
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

      loadRouteUser(routeUser.username);
      notifyListeners();
    });
  }

  Future<void> stopListening() async 
  {
    _conditionTimer?.cancel();
    _conditionTimer = null;
    notifyListeners();    
  }

  Future<void> cancelCurrentPickup() async 
  {
    await _cancelRouteService.cancelRoute(routeUser.username, DateTime.now());
    await _routeService.cancelCurrentPickup(routeUser.username);
    await checkIfRouteActive(routeUser.username);
    loadRouteUser(routeUser.username);
    _notificationProvider.addNotification("Se canceló la recogida para hoy.");
    notifyListeners();
  }

  Future<void> removeCurrentPickup() async 
  {
    await _cancelRouteService.removeCancelRoute(routeUser.username, DateTime.now());
    await _routeService.removeCancelCurrentPickup(routeUser.username);
    await checkIfRouteActive(routeUser.username);
    loadRouteUser(routeUser.username);
    _notificationProvider.addNotification("Se reanudó la recogida para hoy.");
    notifyListeners();
  }



  @override
  void dispose() 
  {
    clearRoutes();
    _conditionTimer?.cancel();
    super.dispose();
  }

  void clearRoutes() 
  {
    isOtherBeingPicked = false;
    routeUser = RouteUser
    (
      fcmToken: '',
      username: '',
      name: '',
      surnames: '',
      phoneNumber: '',
      address: '',
      mail: '',
      isCancelled: false,
      isCollected: false,
      isBeingPicking: false,
      isNear: false,
      distanceInKm: 0.0,
      distanceInMinutes: 0,
    );
    cancelDates.clear();
    isRouteActive = false;
    previousIsGoingToPickUpUser = false;
    previousIsNearToPickUpUser = false;
    notifyListeners();
  }

}
