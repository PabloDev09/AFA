import 'dart:async';
import 'dart:convert';
import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/services/route_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';


class RoutesProvider with ChangeNotifier {
  final RouteService _routeService = RouteService();
  double _distance = 0.0;         // Distancia en km
  double _estimatedTime = 0.0;    // Duración en minutos
  bool _loading = false;
  bool _error = false;
  
  // Ubicación actual del conductor
  LatLng? _driverLocation;
  // Usuario a recoger
  RouteUser? _targetUser;

  Timer? _locationTimer; // Timer para actualizar la ubicación cada 2 segundos

  static const String apiKey = "AIzaSyBTokyGf6XeKvvnn-IU48fi4HyJrKS6PFI";

  // Getters públicos
  double get distance => _distance;
  double get estimatedTime => _estimatedTime;
  bool get isLoading => _loading;
  bool get hasError => _error;
  LatLng? get driverLocation => _driverLocation;
  RouteUser? get targetUser => _targetUser;

  /// Inicia un timer para actualizar la ubicación del conductor cada 2 segundos.
  Future<void> startUpdatingDriverLocation() async {
    // Verificar permisos y obtener la ubicación actual.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("El servicio de ubicación no está habilitado");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Permiso de ubicación denegado");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Permiso de ubicación denegado permanentemente");
    }

    // Inicia el timer para actualizar la posición cada 2 segundos.
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        _driverLocation = LatLng(pos.latitude, pos.longitude);
        notifyListeners();

        // Si ya se ha asignado un usuario destino, recalcula la ruta
        if (_targetUser != null) {
          await calculateRoute();
        }
      } catch (e) {
        print("Error al obtener ubicación del conductor: $e");
      }
    });
  }

  /// Detiene el timer de actualización de la ubicación.
  void stopUpdatingDriverLocation() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  /// Asigna el usuario destino (al cual se va a recoger).
  /// Se espera que el objeto usuario tenga la dirección y la propiedad
  /// isBeingPicked configurada en true.
  void setTargetUser(RouteUser user) {
    _targetUser = user;
    notifyListeners();
    // Calcula la ruta en cuanto se establece el destino, si ya hay ubicación.
    if (_driverLocation != null) {
      calculateRoute();
    }
  }

  /// Calcula la ruta usando la ubicación actual (_driverLocation) como origen
  /// y la dirección del usuario destino (convertida a LatLng) como destino.
  /// Si el tiempo estimado es inferior a 5 minutos, actualiza el objeto _targetUser
  /// para poner isNear en true.
  Future<void> calculateRoute() async {
    if (_driverLocation == null || _targetUser == null) return;
    
    // Primero, obtener las coordenadas de destino a partir de la dirección.
    LatLng destination = await getLatLngFromAddress(_targetUser!.address);

    _loading = true;
    _error = false;
    notifyListeners();

    try {
      final result = await _getRouteMatrix(_driverLocation!, destination);
      _distance = result["distance"];
      _estimatedTime = result["duration"];

      // Actualizar la propiedad isNear si el tiempo es inferior a 5 minutos.
      if (_estimatedTime < 5) {
        _targetUser = RouteUser(
          username: _targetUser!.username,
          name: _targetUser!.name,
          surnames: _targetUser!.surnames,
          address: _targetUser!.address,
          phoneNumber: _targetUser!.phoneNumber,
          isBeingPicking: _targetUser!.isBeingPicking,
          isNear: true,
        );
        _routeService.updateRouteUserIsNear(_targetUser!);
      } else {
        // Asegurarse de que isNear sea false si no se cumple la condición.
        _targetUser = RouteUser(
          username: _targetUser!.username,
          name: _targetUser!.name,
          surnames: _targetUser!.surnames,
          address: _targetUser!.address,
          phoneNumber: _targetUser!.phoneNumber,
          isBeingPicking: _targetUser!.isBeingPicking,
          isNear: false,
        );
      }
    } catch (e) {
      _error = true;
      print("Error en el cálculo de la ruta: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }



  /// Llama a la API de Google para calcular el tiempo y la distancia.
  Future<Map<String, dynamic>> _getRouteMatrix(LatLng origin, LatLng destination) async {
    const String baseUrl = "https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix";
    final Map<String, dynamic> requestBody = {
      "origins": [
        {"waypoint": {"location": {"latLng": {"latitude": origin.latitude, "longitude": origin.longitude}}}}
      ],
      "destinations": [
        {"waypoint": {"location": {"latLng": {"latitude": destination.latitude, "longitude": destination.longitude}}}}
      ],
      "travelMode": "DRIVE",
      "routingPreference": "TRAFFIC_AWARE"
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask": "originIndex,destinationIndex,duration,distanceMeters"
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return {
        "distance": data[0]["distanceMeters"] / 1000, // convierte la distancia a km
        "duration": int.parse(data[0]["duration"].replaceAll('s', '')) / 60 // Convierte el tiempo a minutos
      };
    } else {
      throw Exception("Error en la API: ${response.body}");
    }
  }

Future<LatLng> getLatLngFromAddress(String address) async {
  try {
    List<Location> locations = await locationFromAddress(address);
    if (locations.isNotEmpty) {
      final loc = locations.first;
      return LatLng(loc.latitude, loc.longitude);
    } else {
      throw Exception("No se encontraron coordenadas para la dirección: $address");
    }
  } catch (e) {
    throw Exception("Error al obtener coordenadas para la dirección: $address, Error: $e");
  }
}
}
