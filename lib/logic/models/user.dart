class User 
{
  final String mail;
  final String username;
  final String password;
  final String name;
  final String surnames;
  final String address;
  final String phoneNumber;
  final String rol;
  final bool isActivate;
  final String fcmToken;
  final String numMember;
  final int numRoute;
  final int numPick;
  final String hourPick;

  const User(
  {
    required this.mail,
    required this.username,
    required this.password,
    required this.name,
    required this.surnames,
    required this.address,
    required this.phoneNumber,
    this.rol = "",
    this.isActivate = false,
    this.fcmToken = "",
    this.numMember = "",
    this.numRoute = 0,
    this.numPick = 0,
    this.hourPick = ""
  });

  factory User.fromMap(Map<String, dynamic> data) 
  {
    return User(
      mail: data['mail'] ?? '',
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      name: data['name'] ?? '',
      surnames: data['surnames'] ?? '',
      address: data['address'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      rol: data['rol'] ?? '',
      isActivate: data['isActivate'] ?? false,
      fcmToken: data['fcmToken'] ?? '',
      numMember: data['numMember'] ?? '',
      numRoute: data['numRoute'] ?? 0,
      numPick: data['numPick'] ?? 0,
      hourPick: data['hourPick'] ?? '',
    );
  }

  Map<String, dynamic> toMap() 
  {
    return 
    {
      'mail': mail,
      'username': username,
      'password': password,
      'name': name,
      'surnames': surnames,
      'address': address,
      'phoneNumber': phoneNumber,
      'rol': rol,
      'isActivate': isActivate,
      'fcmToken': fcmToken,
      'numMember':  numMember,
      'numRoute': numRoute,
      'numPick': numPick,
      'hourPick': hourPick
    };
  }

   @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
      mail       == other.mail &&
      username   == other.username &&
      password   == other.password &&
      name       == other.name &&
      surnames   == other.surnames &&
      address    == other.address &&
      phoneNumber== other.phoneNumber &&
      rol        == other.rol &&
      isActivate == other.isActivate &&
      fcmToken   == other.fcmToken &&
      numMember  == other.numMember &&
      numRoute   == other.numRoute &&
      numPick    == other.numPick &&
      hourPick   == other.hourPick;
  }

  @override
  int get hashCode =>
    mail.hashCode       ^
    username.hashCode   ^
    password.hashCode   ^
    name.hashCode       ^
    surnames.hashCode   ^
    address.hashCode    ^
    phoneNumber.hashCode^
    rol.hashCode        ^
    isActivate.hashCode ^
    fcmToken.hashCode   ^
    numMember.hashCode  ^
    numRoute.hashCode   ^
    numPick.hashCode    ^
    hourPick.hashCode;

  bool equals(User other) => this == other;
}
