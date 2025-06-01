import 'package:cloud_firestore/cloud_firestore.dart';

class NumberRouteService {
  final CollectionReference _collectionReferenceRoute = FirebaseFirestore.instance.collection('ruta_numero');

  NumberRouteService();

  Future<int> getMaxRouteNumber() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('ruta_numero')
        .orderBy('numRoute', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return 0;
    return snapshot.docs.first.get('numRoute') as int;
  }

  Future<void> createRouteNumber(int numRoute) async {
    await FirebaseFirestore.instance
        .collection('ruta_numero')
        .add({'numRoute': numRoute});
  }

  Future<void> deleteRouteNumber(int numRoute) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('ruta_numero')
        .where('numRoute', isEqualTo: numRoute)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<bool> existsRoute(int numRoute) async 
  {
    QuerySnapshot snap = await _collectionReferenceRoute
        .where('numRoute', isEqualTo: numRoute)
        .get();

    return snap.docs.isNotEmpty;    
  } 

  // Devuelve todos los numRoute distintos mayores que 0, de forma eficiente
  Future<List<int>> getDistinctRouteNumbers() async {
    QuerySnapshot snapshot = await _collectionReferenceRoute
        .where('numRoute', isGreaterThan: 0)
        .get();

    final Set<int> routeSet = <int>{
      for (final doc in snapshot.docs)
        (doc.get('numRoute') as int)
    };

    // Convertimos a lista ordenada
    final List<int> distinctRoutes = routeSet.toList()..sort();
    return distinctRoutes;
  }

}
