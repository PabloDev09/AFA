import 'package:afa/logic/models/route_driver.dart';
import 'package:afa/logic/models/route_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Utils 
{
  final routeUserNull = RouteUser(fcmToken: '', username: '', name: '', surnames: '', phoneNumber: '', address: '', mail: '', isCancelled: false, isCollected: false, isBeingPicking: false, isNear: false, distanceInKm: 0.0, distanceInMinutes: 0, numRoute: 0, numPick: 0, hourPick: '', createdAt: Timestamp.now());
  final routeDriverNull = RouteDriver(fcmToken: "", username: "", name: "", surnames: "", phoneNumber: "", numRoute: 0, numPick: 0, hasProblem: false, createdAt: Timestamp.now());

  /// Devuelve las iniciales de los apellidos en formato "R. J."
  String surnamesOneLetter(String apellidos) {
    return apellidos
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => '${s[0].toUpperCase()}.')
        .join(' ');
  }

}