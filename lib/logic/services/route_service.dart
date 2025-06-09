import 'dart:async';
import 'dart:convert';

import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:afa/logic/services/driver_route_service.dart';
import 'package:afa/logic/services/cancel_route_service.dart';
import 'package:afa/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/models/cancel_route_user.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteService {
  final UserService _userService = UserService();
  final CancelRouteService _cancelRouteService = CancelRouteService();
  final DriverRouteService _driverRouteService = DriverRouteService();
  final CollectionReference _collectionReferenceRoute =
      FirebaseFirestore.instance.collection('ruta');

  RouteService();

  /// Intenta iniciar la ruta [numRoute] para el conductor [username].
  /// Devuelve true si se asignó correctamente (y creó los usuarios), false en caso contrario.
  Future<bool> createRoute(
    LatLng driverLocation,
    String username,
    int numRoute,
  ) async {
    if (await _driverRouteService.driverHasRoute(username, numRoute)) return false;
    if (await _driverRouteService.countOtherDriversOnRoute(username, numRoute) >= 1) return false;
    
    await _driverRouteService.deleteDriver(username);
    await deleteRoute(numRoute);
    await _driverRouteService.assignDriverToRoute(username, driverLocation, numRoute);
    await _getUsers(driverLocation, numRoute);
    return true;
  }

  /// Elimina todos los documentos de 'ruta' para [numRoute].
  Future<void> deleteRoute(int numRoute) async {
    QuerySnapshot snapshot = await _collectionReferenceRoute
        .where('numRoute', isEqualTo: numRoute)
        .get();
    for (DocumentSnapshot doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<bool> canContinueRoute(int numRoute) async {
    QuerySnapshot snapshot = await _collectionReferenceRoute
        .where('numRoute', isEqualTo: numRoute)
        .get();
    if (snapshot.docs.isEmpty) return false;

    DateTime today = DateTime.now();
    for (DocumentSnapshot doc in snapshot.docs) {
      Timestamp ts = doc.get('createdAt') as Timestamp;
      DateTime created = ts.toDate();
      if (created.year != today.year ||
          created.month != today.month ||
          created.day != today.day) {
        return false;
      }
    }
    return true;
  }

Future<void> pickUpUser(String username, int numRoute, int numPick) async {
  QuerySnapshot snap = await _collectionReferenceRoute
      .where('username', isEqualTo: username)
      .where('numRoute', isEqualTo: numRoute)
      .get();

  if (snap.docs.isNotEmpty) {
    await snap.docs.first.reference.update({
      'isBeingPicking': true,
    });

    await _driverRouteService.setNumPickByNumRoute(numRoute, numPick);
    await _clearRouteIfCompleted(numRoute);
  }
}


  Future<void> cancelPickUpUser(String username, int numRoute) async {
    QuerySnapshot snap = await _collectionReferenceRoute
        .where('username', isEqualTo: username)
        .where('numRoute', isEqualTo: numRoute)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update(<String, dynamic>{
        'isBeingPicking': false,
        'isNear': false,
      });
      
      await _clearRouteIfCompleted(numRoute);
    }
  }

Future<List<RouteUser>> getUsersByStatus({
  required int numRoute,
  required bool Function(RouteUser) filter,
}) async {
  final List<RouteUser> result = [];

  try {
    final QuerySnapshot snapshot = await _collectionReferenceRoute
        .where('numRoute', isEqualTo: numRoute)
        .get();

    for (final DocumentSnapshot doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final routeUser = RouteUser.fromMap(data);
      if (filter(routeUser)) {
        result.add(routeUser);
      }
    }
  } catch (e) {
    // Opcional: puedes agregar un logger o lanzar la excepción
    print('Error al obtener usuarios de la ruta $numRoute: $e');
  }

  return result;
}


  Future<bool> isGoingToPickUpUser(String username) =>
      _checkStatus(username, (RouteUser u) => u.isBeingPicking);

  Future<bool> isNearToPickUpUser(String username) =>
      _checkStatus(username, (RouteUser u) => u.isNear);

  Future<bool> isAnotherUserBeingPicked(String excludeUsername) async {
    QuerySnapshot snapshot = await _collectionReferenceRoute.get();
    for (DocumentSnapshot doc in snapshot.docs) {
      RouteUser ru =
          RouteUser.fromMap(doc.data() as Map<String, dynamic>);
      if (ru.username != excludeUsername && ru.isBeingPicking) {
        return true;
      }
    }
    return false;
  }

  Future<RouteUser?> getRouteUser(String? username) async {
    if (username == null) return null;
    QuerySnapshot snap = await _collectionReferenceRoute
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return RouteUser.fromMap(
        snap.docs.first.data() as Map<String, dynamic>);
  }

  Future<void> markUserAsCollected(String username, int numRoute) async {
    QuerySnapshot snap = await _collectionReferenceRoute
        .where('username', isEqualTo: username)
        .where('numRoute', isEqualTo: numRoute)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference
          .update(<String, dynamic>{'isCollected': true});
      await _clearRouteIfCompleted(numRoute);
    }
  }

  Future<void> cancelCurrentPickup(
      String username, int numRoute) async {
    QuerySnapshot snap = await _collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference
          .update(<String, dynamic>{'isCancelled': true});
      await _cancelRouteService.cancelRoute(username, DateTime.now());
      await _clearRouteIfCompleted(numRoute);
    }
  }

  Future<void> removeCancelCurrentPickup(
      String username, int numRoute) async {
    QuerySnapshot snap = await _collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference
          .update(<String, dynamic>{'isCancelled': false});
      await _cancelRouteService.removeCancelRoute(username, DateTime.now());
      await _clearRouteIfCompleted(numRoute);
    }
  }

  Future<bool> userExistsInRoute(String username) async {
    QuerySnapshot snap = await _collectionReferenceRoute
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> updateAllDistances(
      LatLng driverLocation, int numRoute) async {
    QuerySnapshot snapshot = await _collectionReferenceRoute
        .where('numRoute', isEqualTo: numRoute)
        .get();
    for (DocumentSnapshot doc in snapshot.docs) {
      Map<String, dynamic> data =
          doc.data() as Map<String, dynamic>;
      bool collected = data['isCollected'] as bool;
      bool cancelled = data['isCancelled'] as bool;
      if (collected || cancelled) continue;

      int minutes = 0;
      double distance = 0.0;
      bool near = false;

      try {
        String addr =
            Utils().formatAddressForSearch(data['address'] as String);
        http.Response res = await http
            .get(Uri.parse(
                'https://nominatim.openstreetmap.org/search?q=$addr&format=json'))
            .timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          List<dynamic> list =
              jsonDecode(res.body) as List<dynamic>;
          double lat = double.parse(list[0]['lat'] as String);
          double lon = double.parse(list[0]['lon'] as String);
          LatLng dest = LatLng(lat, lon);

          Map<String, dynamic> matrix =
              await _getRouteMatrix(driverLocation, dest);
          minutes = matrix['duration'] as int;
          distance = matrix['distance'] as double;
          near = distance != 0 && minutes != 0 && minutes <= 5 && (data['isBeingPicking'] as bool);
        }
      } on TimeoutException {
        // silenciar timeout
      }

      await doc.reference.update(<String, dynamic>{
        'distanceInMinutes': minutes,
        'distanceInKm': distance,
        'isNear': near,
      });
    }
    await _clearRouteIfCompleted(numRoute);
  }

Future<Map<String, dynamic>> _getRouteMatrix(
    LatLng origin, LatLng destination) async {
  const String baseUrl =
      'https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix';

  Map<String, dynamic> bodyMap = {
    'origins': [
      {
        'waypoint': {
          'location': {
            'latLng': {
              'latitude': origin.latitude,
              'longitude': origin.longitude,
            }
          }
        }
      }
    ],
    'destinations': [
      {
        'waypoint': {
          'location': {
            'latLng': {
              'latitude': destination.latitude,
              'longitude': destination.longitude,
            }
          }
        }
      }
    ],
    'travelMode': 'DRIVE',
    'routingPreference': 'TRAFFIC_AWARE',
  };

  String body = jsonEncode(bodyMap);

  try {
    http.Response resp = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': 'AIzaSyDdjTRtb1Zp-lz8pY650DIGo137bQh9rig',
        'X-Goog-FieldMask':
            'originIndex,destinationIndex,duration,distanceMeters',
      },
      body: body,
    );

    final dynamic decoded = jsonDecode(resp.body);

    if (decoded is Map<String, dynamic> && decoded.containsKey('error')) {
      return {'distance': 0, 'duration': 0};
    }

    if (decoded is! List || decoded.isEmpty) {
      return {'distance': 0, 'duration': 0};
    }

    final Map<String, dynamic> result = decoded[0];

    final num? distanceMeters = result['distanceMeters'] as num?;
    final String? durationStr = result['duration'] as String?;

    if (distanceMeters == null || durationStr == null) {
      return {'distance': 0, 'duration': 0};
    }

    final double km = distanceMeters / 1000;
    final double secs = double.tryParse(durationStr.replaceAll('s', '')) ?? 0;
    final int mins = (secs / 60).round();

    return {
      'distance': km,
      'duration': mins,
    };
  } catch (e) {
    return {'distance': 0, 'duration': 0};
  }
}


  Future<void> _getUsers(
      LatLng driverLocation, int numRoute) async {
    List<User> users = await _userService
        .getUsersByRolAndNumRoute('Usuario', numRoute);
    List<CancelRouteUser> cancelled =
        await _cancelRouteService.getCanceledUsers();
    DateTime today = DateTime.now();

    for (User user in users) {
      bool isCancelledToday = cancelled.any((CancelRouteUser c) =>
          c.username == user.username &&
          c.cancelDate.year == today.year &&
          c.cancelDate.month == today.month &&
          c.cancelDate.day == today.day);

      int minutes = 0;
      double distance = 0.0;
      bool near = false;

      if (!isCancelledToday) {
        try {
          String addr =
              Utils().formatAddressForSearch(user.address);
          http.Response res = await http
              .get(Uri.parse(
                  'https://nominatim.openstreetmap.org/search?q=$addr&format=json'))
              .timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) {
            List<dynamic> data =
                jsonDecode(res.body) as List<dynamic>;
            double lat = double.parse(
                data[0]['lat'] as String);
            double lon = double.parse(
                data[0]['lon'] as String);
            LatLng dest = LatLng(lat, lon);

            Map<String, dynamic> matrix =
                await _getRouteMatrix(driverLocation, dest);
            minutes = matrix['duration'] as int;  
            distance = matrix['distance'] as double;
            near = minutes <= 5;
          }
        } on TimeoutException {
          // silencioso
        }
      }

      await _collectionReferenceRoute.add(<String, dynamic>{
        'fcmToken': user.fcmToken,
        'mail': user.mail,
        'username': user.username,
        'name': user.name,
        'surnames': Utils().getSurnameInitials(user.surnames),
        'address': user.address,
        'phoneNumber': user.phoneNumber,
        'isBeingPicking': false,
        'isNear': near,
        'isCollected': false,
        'isCancelled': isCancelledToday,
        'distanceInMinutes': minutes,
        'distanceInKm': distance,
        'numRoute': numRoute,
        'numPick': user.numPick,
        'createdAt': Timestamp.now(),
      });
    }

    await _clearRouteIfCompleted(numRoute);
  }

  Future<bool> _checkStatus(
    String username,
    bool Function(RouteUser) condition,
  ) async {
    List<RouteUser> list = await getUsersByStatus(
        filter: (RouteUser u) => u.username == username,
        numRoute: 0 /* not used here */);
    if (list.isEmpty) return false;
    return condition(list.first);
  }

  Future<void> _clearRouteIfCompleted(int numRoute) async {
    QuerySnapshot pendingSnap = await _collectionReferenceRoute
        .where('numRoute', isEqualTo: numRoute)
        .where('isCollected', isEqualTo: false)
        .where('isCancelled', isEqualTo: false)
        .get();

    if (pendingSnap.docs.isEmpty) {
      await deleteRoute(numRoute);
      await _driverRouteService.removeDriverFromRoute(numRoute);
    }
  }
}
