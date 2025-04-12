import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier 
{
  final List<String> notifications = [];

  void addNotification(String notification) 
  {
    notifications.add(notification);
    notifyListeners();
  }

  void clearNotifications() 
  {
    notifications.clear();
    notifyListeners();
  }
}
