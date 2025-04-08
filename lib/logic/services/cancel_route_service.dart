import 'package:afa/logic/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:afa/logic/models/cancel_route_user.dart';

class CancelRouteService {
  UserService userService = UserService();
  final CollectionReference collectionReferenceCancel;

  CancelRouteService()
      : collectionReferenceCancel =
            FirebaseFirestore.instance.collection('rutacancelada');

  Future<void> cancelRoute(String username, DateTime cancelDate) async 
  {
    final docRef = collectionReferenceCancel.doc();
    Map<String, dynamic> data = {
      'username': username,
      'cancelDate': cancelDate,
    };
    await docRef.set(data);
  }

  Future<void> removeCancelRoute(String username, DateTime cancelDate) async {
    QuerySnapshot querySnapshot = await collectionReferenceCancel
        .where('username', isEqualTo: username)
        .where('cancelDate', isEqualTo: Timestamp.fromDate(cancelDate))
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.delete();
    }
  }

  Future<bool> isRouteCanceled(String username, DateTime date) async {
    try {
      QuerySnapshot querySnapshot = await collectionReferenceCancel
          .where('username', isEqualTo: username)
          .where('cancelDate', isEqualTo: Timestamp.fromDate(date))
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error en isRouteCanceled: $e");
      return false;
    }
  }

  Future<List<CancelRouteUser>> getCanceledUsers() async 
  {
    List<CancelRouteUser> canceledUsers = [];
    QuerySnapshot querySnapshot = await collectionReferenceCancel.get();
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final user = CancelRouteUser.fromMap(data);
      canceledUsers.add(user);
    }
    return canceledUsers;
  }

}
