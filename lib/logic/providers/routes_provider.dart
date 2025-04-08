import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RoutesProvider with ChangeNotifier 
{
  double _distance = 0.0;
  double _estimatedTime = 0.0;
  bool _loading = false;
  bool _error = false;

  double get distance => _distance;
  double get estimatedTime => _estimatedTime;
  bool get isLoading => _loading;
  bool get hasError => _error;

  static const String apiKey = "AIzaSyBTokyGf6XeKvvnn-IU48fi4HyJrKS6PFI";

  Future<void> calculateRoute(LatLng origin, LatLng destination) async {
    _loading = true;
    _error = false;
    notifyListeners();

    try {
      final result = await _getRouteMatrix(origin, destination);
      _distance = result["distance"];
      _estimatedTime = result["duration"];
    } catch (e) {
      _error = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

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
        "distance": data[0]["distanceMeters"] / 1000, // Convertir a km
        "duration": int.parse(data[0]["duration"].replaceAll('s', '')) / 60 // Convertir a minutos
      };
    } else {
      throw Exception("Error en la API: ${response.body}");
    }
  }
}