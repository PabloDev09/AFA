import 'package:afa/logic/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:afa/logic/models/cancel_route_user.dart';

class CancelRouteService 
{
  UserService userService = UserService();
  CollectionReference collectionReferenceCancel = FirebaseFirestore.instance.collection('ruta_cancelada');

  CancelRouteService();

  Future<void> cancelRoute(String username, DateTime cancelDate) async 
  {
    final docRef = collectionReferenceCancel.doc();
    Map<String, dynamic> data = 
    {
      'username': username,
      'cancelDate': Timestamp.fromDate(cancelDate),
    };
    await docRef.set(data);
  }

Future<void> removeCancelRoute(String username, DateTime cancelDate) async {
  // Calcula el inicio y fin del día
  final startOfDay = DateTime(cancelDate.year, cancelDate.month, cancelDate.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  // Obtiene todos los documentos del usuario (sin usar rango en Firestore)
  final querySnapshot = await collectionReferenceCancel
      .where('username', isEqualTo: username)
      .get();

  for (final doc in querySnapshot.docs) {
    final ts = doc['cancelDate'] as Timestamp;
    final docDate = ts.toDate();

    // Filtra manualmente por rango de fecha
    if (docDate.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) &&
        docDate.isBefore(endOfDay)) {
      await doc.reference.delete();
    }
  }
}

  Future<List<CancelRouteUser>> getCanceledUsers() async 
  {
    List<CancelRouteUser> canceledUsers = [];
    QuerySnapshot querySnapshot = await collectionReferenceCancel.get();
    
    for (var doc in querySnapshot.docs) 
    {
      final data = doc.data() as Map<String, dynamic>;
      final user = CancelRouteUser.fromMap(data);
      canceledUsers.add(user);
    }
    
    return canceledUsers;
  }

  Future<List<DateTime>> getCancelDatesByUser(String username) async 
  {
    QuerySnapshot querySnapshot = await collectionReferenceCancel
        .where('username', isEqualTo: username)
        .get();

    List<DateTime> cancelDates = querySnapshot.docs.map((doc) 
    {
      final data = doc.data() as Map<String, dynamic>;
      Timestamp timestamp = data['cancelDate'];
      DateTime date = timestamp.toDate();

      return DateTime(date.year, date.month, date.day);
    }).toList();

    return cancelDates;
  }
}
