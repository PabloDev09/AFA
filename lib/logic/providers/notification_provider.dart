import 'package:afa/logic/models/notification.dart';
import 'package:flutter/material.dart' show ChangeNotifier;

class NotificationProvider extends ChangeNotifier 
{
  final List<Notification> notifications = [];

  void addNotification(String notification) 
  {
    notifications.add
    (
      Notification
      (
        message: notification,
        date: DateTime.now(),
        isRead: false,
        isNew: true,
      ),
    );
    notifyListeners();
  }

  void clearNotifications() 
  {
    notifications.clear();
    notifyListeners();
  }

  void markAsReadByIndex(int index) 
  {
    if (index >= 0 && index < notifications.length) 
    {
      notifications[index].isRead = true;
      notifyListeners();
    }
  }

    void markAsReadByNotification(Notification n) 
  {
    if (notifications.contains(n)) 
    {
      notifications[notifications.indexOf(n)].isRead = true;
      notifyListeners();
    }
  }


  bool get hasNewNotification =>
      notifications.any((n) => n.isNew && !n.isRead);

  Notification get latestNotification 
  {
    return notifications.lastWhere((n) => n.isNew && !n.isRead);
  }

  void markLatestAsShown() 
  {
    for (var n in notifications.reversed) 
    {
      if (n.isNew && !n.isRead) 
      {
        n.isNew = false;
        break;
      }
    }
    notifyListeners();
  }
}
