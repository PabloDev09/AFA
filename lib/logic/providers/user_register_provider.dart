import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/helpers/get_provinces_cities.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:flutter/material.dart';

class UserRegisterProvider extends ChangeNotifier {
  String errorMail = "";
  String errorUser = "";
  String? selectedProvince;
  String? selectedCity;
  final GetProvincesCities _getProvincesCities = GetProvincesCities();
  final UserService userService = UserService();
  final List<String> provincesNames = [
    'Almería',
    'Cádiz',
    'Córdoba',
    'Granada',
    'Huelva',
    'Jaén',
    'Málaga',
    'Sevilla'
  ];
  final List<Map<String, String>> provinces = [
    {"provincia": "Jaén", "codigoProvincia": "23"},
    {"provincia": "Granada", "codigoProvincia": "18"},
    {"provincia": "Almería", "codigoProvincia": "04"},
    {"provincia": "Córdoba", "codigoProvincia": "14"},
    {"provincia": "Sevilla", "codigoProvincia": "41"},
    {"provincia": "Málaga", "codigoProvincia": "29"},
    {"provincia": "Huelva", "codigoProvincia": "21"},
    {"provincia": "Cádiz", "codigoProvincia": "11"},
  ];
  List<String> cities = [];
  List<String> domainMails = [
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
  void setSelectedProvince(String province) async {
    selectedProvince = province;
    selectedCity = null; // Resetear la ciudad
    notifyListeners();
  
    String? provinceCode = provinces.firstWhere(
      (element) => element["provincia"] == province,
      orElse: () => {}
    )["codigoProvincia"];
  
    if (provinceCode != null && provinceCode.isNotEmpty) {
      await getCitiesForProvince(provinceCode);
    }
  }
  
  // Actualiza la ciudad seleccionada
  void setSelectedCity(String city) {
    selectedCity = city;
    notifyListeners();
  }
  
  // Obtiene la lista de ciudades para la provincia seleccionada.
  Future<void> getCitiesForProvince(String provinceCode) async {
    try {
      cities = await _getProvincesCities.fetchCities(provinceCode);
    } catch (e) {
      cities = [];
    }
    notifyListeners();
  }
  
   /// Verifica si el correo electrónico tiene un dominio válido.
  bool isCorrectMail(String value) {
    return domainMails.any((domain) => value.endsWith(domain));
  }

  /// Une la dirección con el formato adecuado.
  String joinAddress(String street, String city, String province, String postalCode) {
    return "${street.trim()}, ${city.trim()} (${province.trim()}), ${postalCode.trim()}";
  }

  /// Comprueba si la contraseña cumple con criterios de seguridad.
  bool isSecurePassword(String password) {
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
    );

    try {
      await userService.createUser(userRegister);
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains("El correo ya existe")) {
        errorMail = "El correo ya existe";
      }
      if (errorMsg.contains("El nombre de usuario ya existe")) {
        errorUser = "El nombre de usuario ya existe";
      }
    }
    notifyListeners();
  }

  void _clearErrors() 
  {
    errorMail = "";
    errorUser = "";
  }

String capitalizeEachWord(String input) {
  return input.split(' ').map((word) {
    if (word.isEmpty) return '';
    if (word[0] == '(' && word.length > 1) {
      return '(${word[1].toUpperCase()}${word.substring(2).toLowerCase()}';
    }
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

}


