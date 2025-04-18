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

  /// Al crear una ruta se verifica que todos los documentos de la colección
  /// pertenezcan al día actual. Si se detecta alguno creado en otro día,
  /// se eliminan todos los documentos.
  Future<void> createRoute() async {
    await checkAndDeleteOldRoutes();
    await _getUsers();
  }

  /// Verifica si existe algún documento cuya fecha de creación
  /// (almacenada en el campo 'createdAt') no corresponda con el día actual.
  /// Si se encuentra alguno, se eliminan todos los documentos de la colección.
  Future<void> checkAndDeleteOldRoutes() async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute.get();
    if (querySnapshot.docs.isEmpty) return;

    DateTime now = DateTime.now();
    bool needsDeletion = false;

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      // Se espera que el campo 'createdAt' sea de tipo Timestamp.
      Timestamp? createdAtTimestamp = data['createdAt'];
      if (createdAtTimestamp == null) {
        // Si no está presente la fecha se marca para eliminar.
        needsDeletion = true;
        break;
      }
      DateTime createdAt = createdAtTimestamp.toDate();
      if (createdAt.year != now.year ||
          createdAt.month != now.month ||
          createdAt.day != now.day) {
        // Si la fecha del documento no es la del día actual, se marca para eliminar.
        needsDeletion = true;
        break;
      }
    }
    if (needsDeletion) {
      await deleteRoute();
    }
  }

  /// Elimina todos los documentos de la colección 'ruta'.
  Future<void> deleteRoute() async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute.get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Elimina el documento de la ruta de un usuario específico.
  Future<void> deleteUser(String username) async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.delete();
    }
  }

  /// Actualiza el campo 'isBeingPicking' a true para indicar que se recogió el usuario.
  Future<void> pickUpUser(String username) async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference
          .update({'isBeingPicking': true});
    }
  }

  /// Cancela la recogida de un usuario, actualizando los campos correspondientes.
  Future<void> cancelPickUpUser(String username) async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference
          .update({'isBeingPicking': false, 'isNear': false});
    }
  }

  /// Retorna la lista de usuarios pendientes de recogida.
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

  /// Verifica si se está en proceso de recogida para un usuario determinado.
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

  /// Verifica si el usuario se encuentra cerca para la recogida.
  Future<bool> isNearToPickUpUser(String username) async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      bool isNear = doc.get('isNear');
      return isNear;
    }
    return false;
  }

  /// Actualiza el valor de 'isNear' para un usuario determinado.
  Future<void> updateRouteUserIsNear(RouteUser routeUser) async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: routeUser.username)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.update({
        'isNear': routeUser.isNear,
      });
    } else {
      print("No se encontró un usuario con username: ${routeUser.username}");
    }
  }

  /// Modificación del método canContinueRouteCollection.
  /// Se retornará true solo si existen documentos y TODOS los campos 'createdAt'
  /// tienen la fecha de hoy. En caso contrario, se retorna false.
  Future<bool> canContinueRouteCollection() async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute.get();
    if (querySnapshot.docs.isEmpty) return false;

    DateTime now = DateTime.now();
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      Timestamp? createdAtTimestamp = data['createdAt'];
      if (createdAtTimestamp == null) return false;
      DateTime createdAt = createdAtTimestamp.toDate();
      if (createdAt.year != now.year ||
          createdAt.month != now.month ||
          createdAt.day != now.day) {
        return false;
      }
    }
    return true;
  }

  /// Obtiene los usuarios con rol 'Usuario' y crea un documento por cada uno
  /// en la colección 'ruta' incluyendo la fecha de creación.
  /// Si el usuario canceló la recogida en el día actual se activa la notificación.
  Future<void> _getUsers() async {
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
          // Se añade la fecha de creación del documento.
          'createdAt': Timestamp.now(),
        };
        await collectionReferenceRoute.add(routeData);
      } 
    }
  }
  Future<void> cancelCurrentPickup(String username) async {
    QuerySnapshot querySnapshot = await collectionReferenceRoute
        .where('username', isEqualTo: username)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.delete();
    }
  }
}
