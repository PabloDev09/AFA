import 'package:afa/logic/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:afa/logic/models/user.dart';

class UserPendingProvider extends ChangeNotifier {
  List<String> roles = ['Usuario', 'Conductor','Administrador'];
  final UserService userService = UserService();
  List<User> pendingUsers = [];

  Future<void> chargeUsers() async {
    List<User> users = await userService.getUsers();
    for (User user in users) {
      if (!user.isActivate) {
        pendingUsers.add(user);
      }
    }
    notifyListeners();
  }

  Future<void> acceptUser(User user, String newRole) async
  {
    await userService.acceptUser(user, newRole);
    pendingUsers.removeWhere((u) => u.username == user.username);
    notifyListeners();
  }

  Future<void> updateUser(User user, String email, String username) async 
  {
    await userService.updateUser(user, email, username);
    int index = pendingUsers.indexWhere((u) => u.username == user.username);
    if (index != -1) {
      pendingUsers[index] = user;
      notifyListeners();
    }
  }

  Future<void> deleteUser(User user) async {
    await userService.deleteUser(user.mail, user.username);
    pendingUsers.removeWhere((u) => u.username == user.username);
    notifyListeners();
  }
}
