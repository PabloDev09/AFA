import 'package:afa/logic/models/route_driver.dart';
import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:afa/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverRouteService {
  final CollectionReference _collectionReferenceRoute =
      FirebaseFirestore.instance.collection('ruta_conductor');
  final UserService _userService = UserService();

  DriverRouteService();

  Future<bool> driverHasRoute(String username) async {
    QuerySnapshot snap = await _collectionReferenceRoute
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
  
  Future<RouteDriver?> getDriverByUsername(String username) async {
    final QuerySnapshot snap = await _collectionReferenceRoute
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data() as Map<String, dynamic>;
      return RouteDriver.fromMap(data);
    }
  return null;
}

  Future<RouteDriver?> getDriverByNumRoute(int numRoute) async {
    final QuerySnapshot snap = await _collectionReferenceRoute
        .where('numRoute', isEqualTo: numRoute)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data() as Map<String, dynamic>;
      return RouteDriver.fromMap(data);
    }
  return null;
}


  Future<int> countDriversOnRoute(int numRoute) async {
    QuerySnapshot snap = await _collectionReferenceRoute
        .where('numRoute', isEqualTo: numRoute)
        .get();
    return snap.docs.length;
  }

  Future<void> assignDriverToRoute(String username, int numRoute) async {
    if (await driverHasRoute(username)) return ;
    User? user = await _userService.getUserByUsername(username);
    if (user == null) return ;
    
    RouteDriver driver = RouteDriver(
      fcmToken: user.fcmToken,
      username: user.username,
      name: user.name,
      surnames: Utils().getSurnameInitials(user.surnames),        
      phoneNumber: user.phoneNumber,
      numRoute: numRoute,
      numPick: 0,
      hasProblem: false,
      createdAt: Timestamp.now(),
    );
    await _collectionReferenceRoute.add(driver.toMap());
  }

  Future<void> removeDriverFromRoute(String username) async {
    QuerySnapshot snap = await _collectionReferenceRoute
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.delete();
    }
  }

  Future<void> setNumPickByNumRoute(int numRoute, int numPick) async 
  {
  final snap = await _collectionReferenceRoute
      .where('numRoute', isEqualTo: numRoute)
      .limit(1)
      .get();

  if (snap.docs.isNotEmpty) {
    await snap.docs.first.reference.update({
      'numPick': numPick,
    });
  }
}

  Future<bool> routeHasProblem(int numRoute) async {
  QuerySnapshot snap = await _collectionReferenceRoute
      .where('numRoute', isEqualTo: numRoute)
      .limit(1)
      .get();

  if (snap.docs.isNotEmpty) 
  {
    final data = snap.docs.first.data() as Map<String, dynamic>;
    
    return RouteDriver.fromMap(data).hasProblem;
  }

  return false; 
}


  Future<void> markProblem(String username) async {
    final snap = await _collectionReferenceRoute
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({
        'hasProblem': true,
      });
    }
  }

  Future<void> clearProblem(String username) async {
    final snap = await _collectionReferenceRoute
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({
        'hasProblem': false,
      });
    }
  }
}
