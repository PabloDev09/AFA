class Notification {
  final String notification;
  final DateTime date;
  bool isRead;

  Notification({
    required this.notification,
    required this.date,
    required this.isRead,
  });

  // Método para convertir un Map a un objeto RouteUser
  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      notification: map['notification'] ?? '',
      date: map['date'] ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
}
