import 'package:afa/logic/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:afa/logic/models/user.dart';

class PendingUserProvider extends ChangeNotifier
{
  final UserService _userService = UserService();
  List<User> pendingUsers = [];
  final List<String> rols = ['Usuario', 'Conductor', 'Administrador'];

  Future<void> loadPendingUsers() async 
  {
    List<User> users = await _userService.getUsers();
    pendingUsers = users.where((user) => !user.isActivate).toList();
    notifyListeners();
  }

  Future<void> approveUser(User user, String newRole) async 
  {
    await _userService.acceptUser(user, newRole);
    pendingUsers.removeWhere((u) => u.username == user.username);
    notifyListeners();
  }

  Future<void> updateUser(User user, String email, String username) async 
  {
    await _userService.updateUser(user, email, username);
    int index = pendingUsers.indexWhere((u) => u.username == user.username);

    if (index != -1) 
    {
      pendingUsers[index] = user;
      notifyListeners();
    }
  }

  Future<void> removeUser(User user) async 
  {
    await _userService.deleteUser(user.mail, user.username);
    pendingUsers.removeWhere((u) => u.username == user.username);
    notifyListeners();
  }
}