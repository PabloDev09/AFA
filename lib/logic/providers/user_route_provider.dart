import 'dart:async';
import 'package:afa/logic/models/route_driver.dart';
import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:afa/logic/services/driver_route_service.dart';
import 'package:afa/utils.dart';
import 'package:flutter/material.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:afa/logic/services/cancel_route_service.dart';
import 'package:intl/intl.dart';

class UserRouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();
  final CancelRouteService _cancelRouteService = CancelRouteService();
  final DriverRouteService _driverRouteService = DriverRouteService();
  late NotificationProvider _notificationProvider;

  UserRouteProvider(this._notificationProvider);

  void updateNotificationProvider(NotificationProvider newProvider) {
    _notificationProvider = newProvider;
  }

  RouteDriver routeDriver = Utils().routeDriverNull;
  RouteUser routeUser = Utils().routeUserNull;
  bool isRouteActive = false;
  bool isLoading = false;
  bool isUpdating = false;
  bool isOtherBeingPicked = false;
  bool hasProblem = false;
  bool _isGoingToPickUpUser = false;
  bool _isNearToPickUpUser = false;

  List<DateTime> cancelDates = [];
  Timer? _conditionTimer;

  Future<void> startListening() async {
    _conditionTimer?.cancel();
    _conditionTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      isUpdating = true;
      notifyListeners();

      // 1) Leemos todos los estados remotos
      final auxIsOtherBeingPicked =
          await _routeService.isAnotherUserBeingPicked(routeUser.username);
      final auxIsGoingToPickUpUser =
          await _routeService.isGoingToPickUpUser(routeUser.username);
      final auxIsNearToPickUpUser =
          await _routeService.isNearToPickUpUser(routeUser.username);
      final auxIsRouteActive =
          await _routeService.userExistsInRoute(routeUser.username);
      final auxHasProblem =
          await _driverRouteService.routeHasProblem(routeUser.numRoute);

      // 2) Detectamos cambio de ruta activa
      if (isRouteActive && !auxIsRouteActive) {
        isRouteActive = false;
        clearRoutes();
        _notificationProvider.addNotification("La ruta ha finalizado.", false, false);
        isUpdating = false;
        notifyListeners();
        return;
      }
      isRouteActive = auxIsRouteActive;

      // 3) Recargamos datos de usuario y conductor
      await _getUserAndDriver(routeUser.username);

      // 4) Notificamos cambios de problema
      if (hasProblem != auxHasProblem) {
        hasProblem = auxHasProblem;
        _notificationProvider.addNotification(
          auxHasProblem
              ? "El conductor ha tenido un problema, la ruta ha sido parada temporalmente."
              : "El conductor ha resuelto el problema, la ruta ha sido reactivada.",
          auxHasProblem,
          !auxHasProblem
        );
      }

      // 5) Notificamos cambios de atención a otro pasajero
      if (isOtherBeingPicked != auxIsOtherBeingPicked) {
        isOtherBeingPicked = auxIsOtherBeingPicked;
        _notificationProvider.addNotification(
          "El conductor está atendiendo a otro pasajero.",
          false,
          false
        );
      }

      // 6) Notificamos llegada hacia ti / cancelación
      if (_isGoingToPickUpUser != auxIsGoingToPickUpUser) {
        _isGoingToPickUpUser = auxIsGoingToPickUpUser;
        _notificationProvider.addNotification(
          auxIsGoingToPickUpUser
              ? "Prepárate, el conductor se dirige hacia ti."
              : "La recogida ha sido cancelada por el conductor.",
          false,
          true
        );
      }

      // 7) Notificamos proximidad
      if (_isNearToPickUpUser != auxIsNearToPickUpUser) {
        _isNearToPickUpUser = auxIsNearToPickUpUser;
        _notificationProvider.addNotification(
          "El conductor llegará en aproximadamente 5 minutos.",
          false,
          true
        );
      }

      isUpdating = false;
      notifyListeners();
    });
  }

  Future<void> stopListening() async {
    _conditionTimer?.cancel();
    _conditionTimer = null;
    notifyListeners();
  }

  Future<void> resumeRouteUser(String? username) async {
    if (username == null) return;
    isLoading = true;
    notifyListeners();
    try {
      await _getUserAndDriver(username);
      isRouteActive = true;
      await startListening();
      _notificationProvider.addNotification("La ruta está activa.", false, false);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> canResumeRouteUser(String? username) async {
    if (username == null) return false;
    isLoading = true;
    notifyListeners();
    try {
      return await _routeService.userExistsInRoute(username);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRouteUser(String? username) async {
    if (username == null) return;
    isUpdating = true;
    notifyListeners();
    await _getUserAndDriver(username);
    isUpdating = false;
    notifyListeners();
  }

  Future<void> getCancelDates(String username) async {
    cancelDates = await _cancelRouteService.getCancelDatesByUser(username);
    notifyListeners();
  }

  Future<void> cancelPickupForDate(String username, DateTime cancelDate) async {
    await _cancelRouteService.cancelRoute(username, cancelDate);
    _notificationProvider.addNotification(
      "La recogida del ${DateFormat('dd/MM/yyyy').format(cancelDate.toLocal())} ha sido cancelada correctamente.",
      false,
      false
    );
    await getCancelDates(username);
  }

  Future<void> removeCancelPickupForDate(
      String username,
      DateTime removeCancelDate,
      ) async {
    await _cancelRouteService.removeCancelRoute(username, removeCancelDate);
    _notificationProvider.addNotification(
      "La recogida cancelada del ${DateFormat('dd/MM/yyyy').format(removeCancelDate.toLocal())} ha sido reanudada correctamente.",
      false,
      false
    );
    await getCancelDates(username);
  }

  Future<void> cancelCurrentPickup() async {
    await _routeService.cancelCurrentPickup(routeUser.username, routeUser.numRoute);
    await _getUserAndDriver(routeUser.username);
    _notificationProvider.addNotification("La recogida de hoy ha sido cancelada.", false, false);
  }

  Future<void> removeCancelCurrentPickup() async {
    await _routeService.removeCancelCurrentPickup(routeUser.username, routeUser.numRoute);
    await _getUserAndDriver(routeUser.username);
    _notificationProvider.addNotification("La recogida de hoy ha sido reanudada.", false, false);
  }

  Future<void> _getUserAndDriver(String username) async {
    // Leemos usuario
    final user = await _routeService.getRouteUser(username);
    if (user != null) {
      routeUser = user;
    }
    // Leemos conductor correspondiente a su numRoute
    final driver = await _driverRouteService.getDriverByNumRoute(routeUser.numRoute);
    if (driver != null) {
      routeDriver = driver;
    }
    notifyListeners();
  }

  Future<void> clearRoutes() async {
    await stopListening();
    routeUser = Utils().routeUserNull;
    routeDriver = Utils().routeDriverNull;
    isOtherBeingPicked = false;
    _isGoingToPickUpUser = false;
    _isNearToPickUpUser = false;
    isUpdating = false;
    isLoading = false;
    isRouteActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    clearRoutes();
    super.dispose();
  }
}
