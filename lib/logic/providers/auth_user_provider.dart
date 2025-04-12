import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';

class AuthUserProvider extends ChangeNotifier {
  UserService userService = UserService();
  firebase.User? userFireauth = firebase.FirebaseAuth.instance.currentUser;
  User? userFireStore;
  bool isAuthenticated = false;
  
  Future <void> loadUser() async
  {
    userFireStore = await userService.logUser(userFireauth?.email);
    isAuthenticated = userFireStore != null;
  }

  Future<void> logout() async
  {
    userFireStore = null;
    userFireauth = null;
    isAuthenticated = false;
  }
}

