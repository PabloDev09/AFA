import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:flutter/material.dart';

class UserRegisterProvider extends ChangeNotifier {
  final UserService userService = UserService();

  String errorMail = "";
  String errorUser = "";
  
  String? selectedProvince;
  final List<String> provincesNames = 
  [
    'Almería',
    'Cádiz',
    'Córdoba',
    'Granada',
    'Huelva',
    'Jaén',
    'Málaga',
    'Sevilla'
  ];
  
   String? selectedCity;
  List<String> cities = [];
  List<String> domainMails = 
  [
    "@gmail.com",
    "@yahoo.com",
    "@hotmail.com",
    "@outlook.com",
    "@live.com",
    "@icloud.com",
    "@mail.com",
    "@protonmail.com",
    "@zoho.com",
    "@yandex.com",
    "@gmx.com",
    "@fastmail.com",
  ];
  
  // Actualiza la provincia seleccionada y carga las ciudades asociadas.
  void setSelectedProvince(String province) 
  {
    selectedProvince = province;
    notifyListeners();
  }
  
  // Actualiza la ciudad seleccionada
  void setSelectedCity(String city) 
  {
    selectedCity = city;
    notifyListeners();
  }
  
   /// Verifica si el correo electrónico tiene un dominio válido.
  bool isCorrectMail(String value) 
  {
    return domainMails.any((domain) => value.endsWith(domain));
  }

  /// Une la dirección con el formato adecuado.
  String joinAddress(String street, String city, String province, String postalCode) 
  {
  // Se asegura de que cada parte esté limpia y no vacía, y se une con comas
  List<String> parts = [];
  if (street.trim().isNotEmpty) parts.add(street.trim());
  if (city.trim().isNotEmpty) parts.add(city.trim());
  if (province.trim().isNotEmpty) parts.add(province.trim());
  if (postalCode.trim().isNotEmpty) parts.add(postalCode.trim());  
  parts.add("España");
  
  return parts.join(", ");
  }

  /// Comprueba si la contraseña cumple con criterios de seguridad.
  bool isSecurePassword(String password) 
  {
    return RegExp(
            r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%\^&\*\(\)\-\_\=\+{\}\[\]:;\"<>,\.\?\\/|`~]).{8,}$')
        .hasMatch(password);
  }

  Future<bool> mailExists(String email) async
  {
    return await userService.getUserIdByEmail(email) != null;
  }

  Future<bool> usernameExists(String username) async 
  {
    return await userService.getUserIdByUsername(username) != null;
  }

  /// Registra al usuario en la base de datos.
  Future<void> registerUser({
    required String mail,
    required String username,
    required String password,
    required String name,
    required String surnames,
    required String address,
    required String phoneNumber, 
    required String fcmToken,
  }) async {
    _clearErrors();
    
    User userRegister = User(

      mail: mail,
      username: username,
      password: password,
      name: name,
      surnames: surnames,
      address: address,
      phoneNumber: phoneNumber,
      fcmToken: fcmToken
    );

    try {
      await userService.createUser(userRegister);
    } 
    catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains("El correo ya existe")) 
      {
        errorMail = "El correo ya existe";
      }
      if (errorMsg.contains("El nombre de usuario ya existe")) {
        errorUser = "El nombre de usuario ya existe";
      }
    }
    notifyListeners();
  }



String capitalizeEachWord(String input) 
{
  return input.split(' ').map((word) {
    if (word.isEmpty) return '';
    if (word[0] == '(' && word.length > 1) {
      return '(${word[1].toUpperCase()}${word.substring(2).toLowerCase()}';
    }
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

void _clearErrors() 
{
  errorMail = "";
  errorUser = "";
}

}