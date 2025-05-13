class Notification 
{
  final String message;
  final DateTime date;
  bool isRead;
  bool isNew;

  Notification(
  {
    required this.message,
    required this.date,
    required this.isRead,
    required this.isNew,
  });

  // Método para convertir un Map a un objeto Notification
  factory Notification.fromMap(Map<String, dynamic> map) 
  {
    return Notification(
      message: map['message'] ?? '',
      date: map['date'] ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      isNew: map['isNew'] ?? true,
    );
  }
}