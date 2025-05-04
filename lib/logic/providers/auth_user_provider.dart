import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';

class AuthUserProvider extends ChangeNotifier {
  UserService userService = UserService();
  User? userFireStore;
  bool isAuthenticated = false;
  
  Future <void> loadUser() async
  {
    userFireStore = await userService.logUser(firebase.FirebaseAuth.instance.currentUser?.email);
    isAuthenticated = userFireStore != null;
  }

  Future<void> logout() async
  {
    await firebase.FirebaseAuth.instance.signOut();
    userFireStore = null;
    isAuthenticated = false;
  }
}

