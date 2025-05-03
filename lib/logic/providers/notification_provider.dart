import 'package:afa/logic/models/notification.dart';
import 'package:flutter/material.dart' show ChangeNotifier;

class NotificationProvider extends ChangeNotifier 
{
  final List<Notification> notifications = [];

  void addNotification(String notification) 
  {
    notifications.add(
      Notification
      (
        notification: notification,
        date: DateTime.now(),
        isRead: false,
      ),
    );
    notifyListeners();
  }

  void clearNotifications() 
  {
    notifications.clear();
    notifyListeners();
  }

  void markAsRead(int index) 
  {
    if (index >= 0 && index < notifications.length) 
    {
      notifications[index].isRead = true;
      notifyListeners();
    }
  }
}
