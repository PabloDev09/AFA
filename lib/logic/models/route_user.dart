class RouteUser {
  final String username;
  final String name;
  final String surnames;
  final String address;
  final String phoneNumber;
  final bool isBeingPicking;

  RouteUser({
    required this.username,
    required this.name,
    required this.surnames,
    required this.address,
    required this.phoneNumber,
    required this.isBeingPicking,
  });

  // Método para convertir un Map a un objeto RouteUser
  factory RouteUser.fromMap(Map<String, dynamic> map) {
    return RouteUser(
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      surnames: map['surnames'] ?? '',
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isBeingPicking: map['isBeingPicking'] ?? false,
    );
  }
}
