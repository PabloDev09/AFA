import 'package:cloud_firestore/cloud_firestore.dart';

class NumberRouteService {
  final CollectionReference _collectionReferenceRoute = FirebaseFirestore.instance.collection('ruta_numero');

  NumberRouteService();

  Future<void> createRoute(int numRoute) async 
  {
    if(await existsRoute(numRoute)) return;

    await _collectionReferenceRoute.add
    ({
      'numRoute': numRoute
    });

  }

  Future<void> deleteRoute(int numRoute) async 
  {
    QuerySnapshot snap = await _collectionReferenceRoute
        .where('numRoute', isEqualTo: numRoute).limit(1)
        .get();

    if(snap.docs.isNotEmpty)
    {
          await snap.docs.first.reference.delete();
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
