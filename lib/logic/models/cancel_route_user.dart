import 'package:cloud_firestore/cloud_firestore.dart';

class CancelRouteUser {
  final String username;
  final DateTime cancelDate;

  CancelRouteUser
  ({
  required this.username,
  required this.cancelDate
  });

  factory CancelRouteUser.fromMap(Map<String, dynamic> map) {
    return CancelRouteUser(
      username: map['username'] ?? '',
      cancelDate: (map['cancelDate'] as Timestamp).toDate(),
    );
  }
}
