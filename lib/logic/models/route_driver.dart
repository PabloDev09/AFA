import 'package:cloud_firestore/cloud_firestore.dart';

class RouteDriver
{
  final String fcmToken;
  final String username;
  final String name;
  final String surnames;
  final String phoneNumber;
  final int numRoute;
  final int numPick;
  bool hasProblem;
  GeoPoint location;
  final Timestamp createdAt;

  RouteDriver(
  {
    required this.fcmToken,
    required this.username,
    required this.name,
    required this.surnames,
    required this.phoneNumber,
    required this.numRoute,
    required this.numPick,
    required this.hasProblem,
    required this.location,
    required this.createdAt
  });

  // Método para convertir un Map a un objeto RouteUser
  factory RouteDriver.fromMap(Map<String, dynamic> map) 
  {
    return RouteDriver(
      fcmToken: map['fcmToken'] ?? '',
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      surnames: map['surnames'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      numRoute: map['numRoute'] ?? 0,
      numPick: map['numPick'] ?? 0,
      hasProblem: map['hasProblem'] ?? false,
      location: map['location'] ?? const GeoPoint(0, 0),
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

   /// Convierte este objeto a un Map listo para Firestore
  Map<String, dynamic> toMap() {
    return {
      'fcmToken': fcmToken,
      'username': username,
      'name': name,
      'surnames': surnames,
      'phoneNumber': phoneNumber,
      'numRoute': numRoute,
      'numPick': numPick,
      'hasProblem': hasProblem,
      'location': location,
      'createdAt': createdAt,
    };
  }
}
