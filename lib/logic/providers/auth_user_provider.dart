import 'dart:async';
import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/providers/driver_route_provider.dart';
import 'package:afa/logic/providers/notification_provider.dart';
import 'package:afa/logic/providers/user_route_provider.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';


class AuthUserProvider extends ChangeNotifier 
{
  final UserService _userService = UserService();
  
  NotificationProvider _notificationProvider;
  DriverRouteProvider _driverRouteProvider;
  UserRouteProvider _userRouteProvider;
  User? userFireStore;
  bool isAuthenticated = false;
  Timer? _validationTimer;

  AuthUserProvider(    
    this._notificationProvider,
    this._driverRouteProvider,
    this._userRouteProvider,
    ) 
  {
    _startPeriodicValidation();
  }

  /// Llamado desde el ProxyProvider para inyectar las dependencias actualizadas.
  void updateDependencies({
    required NotificationProvider notificationProvider,
    required DriverRouteProvider driverRouteProvider,
    required UserRouteProvider userRouteProvider,
  }) {
    _notificationProvider = notificationProvider;
    _driverRouteProvider = driverRouteProvider;
    _userRouteProvider = userRouteProvider;
  }

  Future<void> loadUser() async {
    userFireStore =
        await _userService.logUser(firebase.FirebaseAuth.instance.currentUser?.email);
    isAuthenticated = userFireStore != null;
    notifyListeners();
  }

  Future<void> logout() async {
    await firebase.FirebaseAuth.instance.signOut();
    _notificationProvider.clearNotifications();
    _driverRouteProvider.clearRoutes();
    _userRouteProvider.clearRoutes();
    userFireStore = null;
    isAuthenticated = false;
    _validationTimer?.cancel();
    notifyListeners();
  }

  Future<bool> verifyPassword(String email, String password) async {
    try {
      final credential = firebase.EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await firebase.FirebaseAuth.instance.currentUser
          ?.reauthenticateWithCredential(credential);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Inicia comprobación cada 15 minutos de que el usuario en Firestore coincide con el local
  Future<void> _startPeriodicValidation() async {
    _validationTimer?.cancel();
    _validationTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      if(userFireStore == null) return;
      if(await _userService.checkUser(userFireStore) == false)
      {
        logout();
      }
    });
  }


  @override
  void dispose() {
    _validationTimer?.cancel();
    super.dispose();
  }
}
