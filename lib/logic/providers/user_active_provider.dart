import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:flutter/material.dart';

class UserActiveProvider extends ChangeNotifier 
{
  final UserService userService = UserService();
  
  List<User> activeUsers = [];

  Future<void> chargeUsers() async 
  {
    List<User> users = await userService.getUsers();
    for (User user in users) 
    {
      if (user.mail.trim().isNotEmpty && user.isActivate && user.rol.trim().isNotEmpty)
      {
        activeUsers.add(user);
      }
    }
    notifyListeners();
  }

  Future<bool> authenticateUser(String email, String username, String password) async 
  {
  return await userService.authenticateUser(email, username, password);
  }

  void removeUser(User user) 
  {
    activeUsers.remove(user);
    notifyListeners();
  }
}
