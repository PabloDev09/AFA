import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:flutter/material.dart';

class ActiveUserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  List<User> activeUsers = [];

  Future<void> loadActiveUsers() async {
    List<User> users = await _userService.getUsers();

    activeUsers = users.where((user) => user.isActivate && user.rol.trim().isNotEmpty).toList();
    
    notifyListeners();
  }

  Future<bool> authenticateGoogleUser(String email) async {
    return await _userService.authenticateGoogleUser(email);
  }

  Future<bool> authenticateUser(String email, String password) async {
    return await _userService.authenticateUser(email, password);
  }

  Future<void> updateUser(User user, String email, String username) async {
    await _userService.updateUser(user, email, username);
    int index = activeUsers.indexWhere((u) => u.username == user.username);
    
    if (index != -1) {
      activeUsers[index] = user;
      notifyListeners();
    }
  }

  Future<void> deleteUser(User user) async {
    await _userService.deleteUser(user.mail, user.username);
    activeUsers.removeWhere((u) => u.username == user.username);
    notifyListeners();
  }
}
