class CancelRouteUser {
  final String username;
  final DateTime cancelDate;

  CancelRouteUser
  ({
  required this.username,
  required this.cancelDate
  });

  // Método para convertir un Map a un objeto CancelRouteUser
  factory CancelRouteUser.fromMap(Map<String, dynamic> map) {
    return CancelRouteUser(
      username: map['username'] ?? '',
      cancelDate: map['cancelDate'] ?? DateTime.now()
    );
  }
}
