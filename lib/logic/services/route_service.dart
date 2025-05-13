import 'dart:async';
import 'dart:convert';

import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/models/cancel_route_user.dart';
import 'package:afa/logic/services/cancel_route_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteService 
{
  UserService userService = UserService();
  CancelRouteService cancelRouteService = CancelRouteService();
  CollectionReference collectionReferenceRoute = FirebaseFirestore.instance.collection('ruta');

  RouteService();

  /// Crea una ruta para el conductor, eliminando la ruta anterior y obteniendo
  /// los usuarios pendientes de recogida.
  Future<void> createRoute(LatLng driverLocation) async 
  {
    await deleteRoute();
    await _getUsers(driverLocation);
  }

  /// Elimina todos los documentos de la colección 'ruta'.
  Future<void> deleteRoute() async 
  {
    QuerySnapshot querySnapshot = await collectionReferenceRoute.get();
    for (var doc in querySnapshot.docs) 
    {
      await doc.reference.delete();
    }
  }

  /// Actualiza el campo 'isBeingPicking' a true para indicar que se recogió el usuario.
  Future<void> pickUpUser(String username) async 
  {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) 
    {
      await querySnapshot.docs.first.reference
          .update({'isBeingPicking': true});
    }
  }

  /// Cancela la recogida de un usuario, actualizando los campos correspondientes.
  Future<void> cancelPickUpUser(String username) async 
  {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) 
    {
      await querySnapshot.docs.first.reference
          .update({'isBeingPicking': false, 'isNear': false});
    }
  }

  /// Retorna la lista de usuarios por filtro
  Future<List<RouteUser>> getUsersByStatus({
    required bool Function(RouteUser user) filter,
  }) async {
    List<RouteUser> filteredUsers = [];
    QuerySnapshot querySnapshot = await collectionReferenceRoute.get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final routeUser = RouteUser.fromMap(data);

      if (filter(routeUser)) {
        filteredUsers.add(routeUser);
      }
    }

    return filteredUsers;
  }

/// Método genérico reutilizable para validar un estado de usuario
Future<bool> checkUserStatus(String username, bool Function(RouteUser) condition) async {
  QuerySnapshot snapshot = await collectionReferenceRoute.get();

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final user = RouteUser.fromMap(data);

    if (user.username == username && condition(user)) {
      return true;
    }
  }

  return false;
}


  /// Verifica si se está en proceso de recogida para un usuario determinado.
  Future<bool> isGoingToPickUpUser(String username) async 
  {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) 
    {
      final doc = querySnapshot.docs.first;
      bool isBeingPicking = doc.get('isBeingPicking');
      return isBeingPicking;
    }
    return false;
  }

  /// Verifica si hay otro usuario siendo recogido, excluyendo a uno específico.
  Future<bool> isAnotherUserBeingPicked(String excludeUsername) async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute.get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final username = data['username'];
      final isBeingPicked = data['isBeingPicking'];

      if (username != excludeUsername && isBeingPicked == true) {
        return true;
      }
    }

    return false;
  }


  /// Verifica si el usuario se encuentra cerca para la recogida.
  Future<bool> isNearToPickUpUser(String username) async 
  {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) 
    {
      final doc = querySnapshot.docs.first;
      bool isNear = doc.get('isNear');
      return isNear;
    }
    return false;
  }

  /// Modificación del método canContinueRouteCollection.
  /// Se retornará true solo si existen documentos y TODOS los campos 'createdAt'
  /// tienen la fecha de hoy. En caso contrario, se retorna false.
  Future<bool> canContinueRouteCollection() async 
  {
    // 1) Trae todos los documentos
    final snapshot = await collectionReferenceRoute.get();
    if (snapshot.docs.isEmpty) return false;

    // 2) Crea un DateTime que represente “hoy a medianoche”
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 3) Recorre cada documento y comprueba su createdAt
    for (var doc in snapshot.docs) 
    {
      final data = doc.data() as Map<String, dynamic>;
      Timestamp ts = data['createdAt'];
      final dt = ts.toDate();
      final createdDate = DateTime(dt.year, dt.month, dt.day);

      if (createdDate != today) 
      {
        return false;
      }
    }

    return true;
  }

Future<RouteUser?> loadRouteUser(String? username) async {
  if (username == null) return null;

  final querySnapshot = await collectionReferenceRoute
      .where('username', isEqualTo: username)
      .limit(1)
      .get();

  if (querySnapshot.docs.isEmpty) return null;

  final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
  return RouteUser.fromMap(data);
}


  /// Obtiene los usuarios con rol 'Usuario' y crea un documento por cada uno
  /// en la colección 'ruta' incluyendo la fecha de creación.
  /// Si el usuario canceló la recogida en el día actual se activa la notificación.
  Future<void> _getUsers(LatLng driverLocation) async 
  {
    List<User> usersRol = await userService.getUsersByRol('Usuario');
    List<CancelRouteUser> cancelledUsers = await cancelRouteService.getCanceledUsers();
    DateTime now = DateTime.now();

    for (var user in usersRol) 
    {
      bool isCancelledToday = cancelledUsers.any((cancelledUser) =>
        cancelledUser.username == user.username &&
        cancelledUser.cancelDate.year == now.year &&
        cancelledUser.cancelDate.month == now.month &&
        cancelledUser.cancelDate.day == now.day
      );

      LatLng dest;
      int minutes = 0;
      int distance = 0;

      if (!isCancelledToday) 
      {
        final address = user.address;
        final formattedAddress = _formatAddressForSearch(address);
        try 
        {
          final response = await http
              .get(Uri.parse('https://nominatim.openstreetmap.org/search?q=$formattedAddress&format=json'))
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) 
          {
          final data = jsonDecode(response.body);
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          dest = LatLng(lat, lon);
          final matrix = await _getRouteMatrix(driverLocation, dest);

          minutes = matrix['duration'] is int
              ? matrix['duration']
              : (matrix['duration'] as double).toInt();

          distance = matrix['distance'] is int
              ? matrix['distance']
              : (matrix['distance'] as double).toInt();
          }
          
        } 
        on TimeoutException 
        // ignore: empty_catches
        {
        } 
      }

      Map<String, dynamic> routeData = 
      {
        'fcmToken': user.fcmToken,
        'mail': user.mail,
        'username': user.username,
        'name': user.name,
        'surnames': user.surnames,
        'address': user.address,
        'phoneNumber': user.phoneNumber,
        'isBeingPicking': false,
        'isNear': false,
        'isCollected': false,
        'isCancelled': isCancelledToday,
        'distanceInMinutes': minutes,
        'distanceInKm': distance,
        'createdAt': Timestamp.now(),
      };
      await collectionReferenceRoute.add(routeData);
    }
  }

  /// Marca a un usuario como recogido, actualizando el campo 'isCollected'.
  Future<void> markUserAsCollected(String username) async 
  {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) 
    {
      await querySnapshot.docs.first.reference.update({'isCollected': true});
    }
  }

  /// Cancela la recogida actual de un usuario, actualizando el campo 'isCancelled'.
  Future<void> cancelCurrentPickup(String username) async 
  {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) 
    {
      await querySnapshot.docs.first.reference.update({'isCancelled': true});
    }
  }

    /// Remueve la cancelacion de la recogida actual de un usuario, actualizando el campo 'isCancelled'.
  Future<void> removeCancelCurrentPickup(String username) async 
  {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) 
    {
      await querySnapshot.docs.first.reference.update({'isCancelled': false});
    }
  }

  /// Comprueba si ya existe un documento de ruta para el username dado.
  Future<bool> userExistsInRoute(String username) async 
  {  
    final query = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Actualiza la distancia y el tiempo de todos los usuarios en la ruta
  Future<void> updateAllDistances(LatLng driverLocation) async 
  {
    QuerySnapshot snapshot = await collectionReferenceRoute.get();

    for (var doc in snapshot.docs) 
    {
     if (doc.get('isCollected') == true) continue;
      if (doc.get('isCancelled') == true) continue;

      final dataDoc = doc.data() as Map<String, dynamic>;
      final address = dataDoc['address'] as String;
      final isBeingPicking = dataDoc['isBeingPicking'] as bool;
      final formattedAddress = _formatAddressForSearch(address);
      LatLng dest;
      int minutes = 0;
      int distance = 0;
      bool near = false;

      try 
      {
        final response = await http
            .get(Uri.parse('https://nominatim.openstreetmap.org/search?q=$formattedAddress&format=json'))
            .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) 
          {
          final data = jsonDecode(response.body);
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          dest = LatLng(lat, lon);
          final matrix = await _getRouteMatrix(driverLocation, dest);

          minutes = matrix['duration'] is int
              ? matrix['duration']
              : (matrix['duration'] as double).toInt();

          distance = matrix['distance'] is int
              ? matrix['distance']
              : (matrix['distance'] as double).toInt();

            near = minutes <= 5 && isBeingPicking;
        }
      } 
      on TimeoutException 
      // ignore: empty_catches
      {
      }
       
       await doc.reference.update(
      {
        'distanceInKm': distance,
        'distanceInMinutes': minutes,
        'isNear': near,
      });
    }
  }

  Future<Map<String, dynamic>> _getRouteMatrix(LatLng origin, LatLng destination) async 
  {
    const String baseUrl = "https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix";
    final Map<String, dynamic> requestBody = 
    {
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
      headers: 
      {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": "AIzaSyDdjTRtb1Zp-lz8pY650DIGo137bQh9rig",
        "X-Goog-FieldMask": "originIndex,destinationIndex,duration,distanceMeters"
      },
      body: jsonEncode(requestBody),
    );

    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded.containsKey('error')) 
    {
      throw Exception("Error en la API: ${decoded['error']['message']}");
    }
    if (decoded is! List || decoded.isEmpty) 
    {
      throw Exception("La respuesta de la API no es una lista válida o está vacía.");
    }

    final distance = decoded[0]["distanceMeters"] / 1000; // km
    final durationSeconds = double.parse(decoded[0]["duration"].replaceAll('s', ''));
    final durationMinutes = (durationSeconds / 60).round();

    return 
    {
      "distance": distance,
      "duration": durationMinutes,
    };
  }

  _formatAddressForSearch(String address) 
  {
    String cleaned = address.replaceAll(',', '').trim();
    String formatted = cleaned.replaceAll(RegExp(r'\s+'), '+');

    return formatted;
  }


}
