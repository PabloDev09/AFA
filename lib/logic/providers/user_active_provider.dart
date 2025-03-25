import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:flutter/material.dart';

class UserActiveProvider extends ChangeNotifier {
  UserService userService = UserService();
  List<User> activeUsers = [];

  Future<void> chargeUsers() async {
    List<User> users = await userService.getUsers();

    activeUsers.clear();
    
    for (User user in users) {
      if (user.isActivate && user.rol.trim().isNotEmpty) {
        activeUsers.add(user);
      }
    }
    notifyListeners();
  }

  Future<bool> authenticateUser(String email, String username, String password) async 
  {
    return await userService.authenticateUser(email, username, password);
  }

  Future<void> updateUser(User user, String email, String username) async {
    await userService.updateUser(user, email, username);
    int index = activeUsers.indexWhere((u) => u.username == user.username);
    if (index != -1) {
      activeUsers[index] = user;
      notifyListeners();
    }
  }

  Future<void> deleteUser(User user) async {
    await userService.deleteUser(user.mail, user.username);
    activeUsers.removeWhere((u) => u.username == user.username);
    notifyListeners();
  }
}
