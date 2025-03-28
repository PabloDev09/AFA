import 'package:afa/logic/models/user.dart';
import 'package:afa/logic/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:afa/logic/models/route_user.dart'; 

class RouteService {
  UserService userService = UserService();
  final CollectionReference collectionReferenceRoute;
  
  RouteService() : collectionReferenceRoute = FirebaseFirestore.instance.collection('ruta');

  Future<void> createRouteCollection() async {
    deleteRouteCollection();
    await _getRolUsers();
  }

  Future<bool> canContinueRouteCollection() async {
    List<RouteUser> usersToPickUp = await getUsersToPickUp();

    if(usersToPickUp.isNotEmpty)
    {
      return true;
    }

    return false;
  }

  Future<void> deleteRouteCollection() async {
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
      await querySnapshot.docs.first.reference.update({'isBeingPicking': true});
    }
  }

    Future<void> cancelPickUpUser(String username) async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.update({'isBeingPicking': false});
    }
  }

  Future<List<RouteUser>> getUsersToPickUp() async {
    List<RouteUser> usersToPickUp = [];
    QuerySnapshot queryUsersToPickUp = await collectionReferenceRoute.get();

    for (var userToPickUp in queryUsersToPickUp.docs) {
      final data = userToPickUp.data() as Map<String, dynamic>;
      final routeUser = RouteUser.fromMap(data);
      usersToPickUp.add(routeUser);
    }

    return usersToPickUp;
  }


  Future<void> _getRolUsers() async {
    List<User> usersRol = await userService.getUsersByRol('Usuario');
    for (var user in usersRol) 
    {
      Map<String, dynamic> routeData = 
      {
        'username': user.username,
        'name': user.name,
        'surnames': user.surnames,
        'address': user.address,
        'phoneNumber': user.phoneNumber,
        'isBeingPicking': false,
      };
      await collectionReferenceRoute.add(routeData);
    }
  }

}
