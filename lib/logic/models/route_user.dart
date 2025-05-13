class RouteUser 
{
  final String fcmToken;
  final String mail;
  final String username;
  final String name;
  final String surnames;
  final String address;
  final String phoneNumber;
  final bool isBeingPicking;
  final bool isNear;
  final bool isCollected;
  final bool isCancelled;
  final int distanceInMinutes;
  final double distanceInKm;

  RouteUser(
  {
    required this.fcmToken,
    required this.mail,
    required this.username,
    required this.name,
    required this.surnames,
    required this.address,
    required this.phoneNumber,
    required this.isBeingPicking,
    required this.isNear,
    required this.isCollected,
    required this.isCancelled,
    required this.distanceInMinutes,
    required this.distanceInKm,
  });

  // Método para convertir un Map a un objeto RouteUser
  factory RouteUser.fromMap(Map<String, dynamic> map) 
  {
    return RouteUser(
      fcmToken: map['fcmToken'] ?? '',
      mail: map['mail'] ?? '',
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      surnames: map['surnames'] ?? '',
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isBeingPicking: map['isBeingPicking'] ?? false,
      isNear: map['isNear'] ?? false,
      isCollected: map['isCollected'] ?? false,
      isCancelled: map['isCancelled'] ?? false,
      distanceInMinutes: map['distanceInMinutes'] ?? 0,
      distanceInKm: map['distanceInKm']?.toDouble() ?? 0.0,
    );
  }
}
