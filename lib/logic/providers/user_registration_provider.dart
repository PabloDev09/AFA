import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/helpers/get_provinces_cities.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:flutter/material.dart';

class UserRegistrationProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  final GetProvincesCities _provinceCityHelper = GetProvincesCities();
  
  String emailError = "";
  String usernameError = "";
  String? selectedProvince;
  String? selectedCity;
  
  final List<String> provinceNames = [
    'Almería', 'Cádiz', 'Córdoba', 'Granada', 
    'Huelva', 'Jaén', 'Málaga', 'Sevilla'
  ];

  final List<Map<String, String>> provinces = [
    {"province": "Jaén", "provinceCode": "23"},
    {"province": "Granada", "provinceCode": "18"},
    {"province": "Almería", "provinceCode": "04"},
    {"province": "Córdoba", "provinceCode": "14"},
    {"province": "Sevilla", "provinceCode": "41"},
    {"province": "Málaga", "provinceCode": "29"},
    {"province": "Huelva", "provinceCode": "21"},
    {"province": "Cádiz", "provinceCode": "11"},
  ];
  
  List<String> cities = [];
  
  final List<String> validEmailDomains = [
    "@gmail.com", "@yahoo.com", "@hotmail.com", "@outlook.com",
    "@live.com", "@icloud.com", "@mail.com", "@protonmail.com",
    "@zoho.com", "@yandex.com", "@gmx.com", "@fastmail.com",
  ];
  
  void updateSelectedProvince(String province) async {
    selectedProvince = province;
    selectedCity = null;
    notifyListeners();

    String? provinceCode = provinces.firstWhere(
      (element) => element["province"] == province,
      orElse: () => {}
    )["provinceCode"];

    if (provinceCode != null && provinceCode.isNotEmpty) {
      await fetchCitiesForProvince(provinceCode);
    }
  }

  void updateSelectedCity(String city) {
    selectedCity = city;
    notifyListeners();
  }

  Future<void> fetchCitiesForProvince(String provinceCode) async {
    try {
      cities = await _provinceCityHelper.fetchCities(provinceCode);
    } catch (e) {
      cities = [];
    }
    notifyListeners();
  }

  bool isValidEmailDomain(String value) {
    return validEmailDomains.any((domain) => value.endsWith(domain));
  }

  String formatAddress(String street, String city, String province, String postalCode) {
    return "${street.trim()}, ${city.trim()} (${province.trim()}), ${postalCode.trim()}";
  }

  bool isStrongPassword(String password) {
    return RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%\^&\*\(\)\-\_\=\+{\}\[\]:;\"<>,\.\?\\/|`~]).{8,}$'
    ).hasMatch(password);
  }

  Future<bool> emailExists(String email) async {
    return await _userService.getUserIdByEmail(email) != null;
  }

  Future<bool> usernameExists(String username) async {
    return await _userService.getUserIdByUsername(username) != null;
  }

  Future<void> registerUser({
    required String email,
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String address,
    required String phoneNumber,
  }) async {
    _clearErrors();

    User newUser = User(
      mail: email,
      username: username,
      password: password,
      name: firstName,
      surnames: lastName,
      address: address,
      phoneNumber: phoneNumber,
    );

    try {
      await _userService.createUser(newUser);
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains("Email already exists")) {
        emailError = "Email already exists";
      }
      if (errorMsg.contains("Username already exists")) {
        usernameError = "Username already exists";
      }
    }
    notifyListeners();
  }

  void _clearErrors() {
    emailError = "";
    usernameError = "";
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
