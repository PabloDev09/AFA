import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:afa/logic/models/route_user.dart';
import 'package:afa/logic/models/cancel_route_user.dart';
import 'package:afa/logic/services/cancel_route_service.dart';

class RouteService {
  UserService userService = UserService();
  CancelRouteService cancelRouteService = CancelRouteService();
  final CollectionReference collectionReferenceRoute;

  RouteService()
      : collectionReferenceRoute =
            FirebaseFirestore.instance.collection('ruta');

  Future<void> createRoute({Function(String)? addNotification}) async {
    await deleteRoute();
    await _getUsers(addNotification);
  }

  Future<bool> canContinueRouteCollection() async {
    List<RouteUser> usersToPickUp = await getUsersToPickUp();
    return usersToPickUp.isNotEmpty;
  }

  Future<void> deleteRoute() async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute.get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deleteUser(String username) async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.delete();
    }
  }

  Future<void> pickUpUser(String username) async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference
          .update({'isBeingPicking': true});
    }
  }

  Future<void> cancelPickUpUser(String username) async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference
          .update({'isBeingPicking': false});
    }
  }

  Future<List<RouteUser>> getUsersToPickUp() async {
    List<RouteUser> usersToPickUp = [];
    QuerySnapshot querySnapshot = await collectionReferenceRoute.get();
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final routeUser = RouteUser.fromMap(data);
      usersToPickUp.add(routeUser);
    }
    return usersToPickUp;
  }

  Future<bool> isGoingToPickUpUser(String username) async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      bool isBeingPicking = doc.get('isBeingPicking');
      return isBeingPicking;
    }
    return false;
  }

  Future<void> _getUsers(Function(String)? addNotification) async {
    List<User> usersRol = await userService.getUsersByRol('Usuario');
    List<CancelRouteUser> cancelledUsers =
        await cancelRouteService.getCanceledUsers();
    DateTime now = DateTime.now();
    for (var user in usersRol) {
      bool isCancelledToday = cancelledUsers.any((cancelledUser) =>
          cancelledUser.username == user.username &&
          cancelledUser.cancelDate.year == now.year &&
          cancelledUser.cancelDate.month == now.month &&
          cancelledUser.cancelDate.day == now.day);
      if (!isCancelledToday) {
        Map<String, dynamic> routeData = {
          'username': user.username,
          'name': user.name,
          'surnames': user.surnames,
          'address': user.address,
          'phoneNumber': user.phoneNumber,
          'isBeingPicking': false,
          'isNear': false,
        };
        await collectionReferenceRoute.add(routeData);
      } else {
        if (addNotification != null) {
          addNotification("${user.name} ${user.surnames} canceló la recogida hoy.");
        }
      }
    }
  }
  Future<void> updateRouteUserIsNear(RouteUser routeUser) async {
  // Buscamos el documento correspondiente en la colección 'ruta' por el username.
  QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('ruta')
      .where('username', isEqualTo: routeUser.username)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    // Actualizamos el campo 'isNear' usando el valor del objeto recibido.
    await querySnapshot.docs.first.reference.update({
      'isNear': routeUser.isNear,
    });
  } else {
    print("No se encontró un usuario con username: ${routeUser.username}");
  }
}
}
