import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';

class AuthUserProvider extends ChangeNotifier {
  firebase.User? userFireauth = firebase.FirebaseAuth.instance.currentUser;
  User? userFireStore;
  UserService userService = UserService();
  bool isAuthenticated = false;
  
  Future <void> loadUser() async{
    userFireStore = await userService.logUser(userFireauth?.email);
    isAuthenticated = userFireStore != null;
  }
}

