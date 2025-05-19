import 'package:afa/logic/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService 
{
  final CollectionReference collectionReferenceUsers = FirebaseFirestore.instance.collection('usuarios');

  UserService();

  Future<void> createUser(User userRegister) async 
  {
    await collectionReferenceUsers.add({
      'mail': userRegister.mail,
      'username': userRegister.username,
      'password': userRegister.password,
      'name': userRegister.name,
      'surnames': userRegister.surnames,
      'address': userRegister.address,
      'phoneNumber': userRegister.phoneNumber,
      'rol': userRegister.rol,
      'isActivate': userRegister.isActivate,
      'fcmToken': userRegister.fcmToken
    });
  }


  Future<bool> checkUser(User? localUser) async 
  {
    if (localUser == null) return false;

    final query = await collectionReferenceUsers
        .where('username', isEqualTo: localUser.username)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    // Mapear datos remotos a User
    final remoteData = query.docs.first.data() as Map<String, dynamic>;
    final remoteUser = User.fromMap(remoteData);

    // Usamos tu método equals de la clase User
    final isEqual = localUser.equals(remoteUser);

    return isEqual;
  }

  Future<List<User>> getUsers() async {
    List<User> usersRegister = [];
    QuerySnapshot queryUsers = await collectionReferenceUsers.get();

    for (var documento in queryUsers.docs) 
    {
      final data = documento.data() as Map<String, dynamic>;
      final user = User.fromMap(data);
      usersRegister.add(user);
    }

    return usersRegister;
  }

  Future<List<User>> getUsersByRolAndNumRoute(String rol, int numRoute) async {
    QuerySnapshot querySnapshot = await collectionReferenceUsers
        .where('rol', isEqualTo: rol)
        .where('numRoute', isEqualTo: numRoute)
        .get();

    List<User> users = <User>[];
    for (DocumentSnapshot documento in querySnapshot.docs) {
      Map<String, dynamic> data = documento.data() as Map<String, dynamic>;
      User user = User.fromMap(data);
      users.add(user);
    }
    return users;
  }

  /// Obtiene un User por su username, o null si no existe
  Future<User?> getUserByUsername(String username) async {
    QuerySnapshot snap = await collectionReferenceUsers
      .where('username', isEqualTo: username)
      .limit(1)
      .get();
    if (snap.docs.isEmpty) {
      return null;
    }
    // Mapeamos el primer documento a User
    Map<String, dynamic> data = snap.docs.first.data() as Map<String, dynamic>;
    return User.fromMap(data);
  }

  Future<String?> getUserIdByEmail(String email) async {
    QuerySnapshot queryByEmail = await collectionReferenceUsers
        .where('mail', isEqualTo: email)
        .limit(1)
        .get();
    if (queryByEmail.docs.isNotEmpty) {
      return queryByEmail.docs.first.id;
    }
    return null;
  }

  Future<String?> getUserIdByUsername(String username) async {
    QuerySnapshot queryByUsername = await collectionReferenceUsers
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (queryByUsername.docs.isNotEmpty) {
      return queryByUsername.docs.first.id;
    }
    return null;
  }

  Future<void> updateUser(User user, String email, String username) async {
    String? userId = await getUserIdByEmail(email);
    userId ??= await getUserIdByUsername(username);

    if (userId != null) {
      await collectionReferenceUsers.doc(userId).update({
        'mail': user.mail,
        'username': user.username,
        'password': user.password,
        'name': user.name,
        'surnames': user.surnames,
        'address': user.address,
        'phoneNumber': user.phoneNumber,
        'rol': user.rol,
        'isActivate': user.isActivate,
        'fcmToken': user.fcmToken,
        'numRoute':user.numRoute,
        'numPick':user.numPick
      });
    } else {
      throw Exception("Usuario no encontrado");
    }
  }

  Future<void> deleteUser(String email, String username) async {
    String? userId = await getUserIdByEmail(email);
    userId ??= await getUserIdByUsername(username);

    if (userId != null) {
      await collectionReferenceUsers.doc(userId).delete();
    } else {
      throw Exception("Usuario no encontrado");
    }
  }

Future<bool> authenticateUser(String email, String password) async {
  String? userId = await getUserIdByEmail(email);
  if (userId != null) {
    DocumentSnapshot doc = await collectionReferenceUsers.doc(userId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      // Comprueba que el usuario esté activado
      final isActivate = data['isActivate'] as bool? ?? false;
      if (!isActivate) {
        return false;
      }

      // Comprueba la contraseña
      if (data['password'] == password) {
        return true;
      }
    }
  }
  return false;
}

  Future<User?> logUser(String? email) async {
  String? userId = await getUserIdByEmail(email!);
  
  if (userId != null) {
    DocumentSnapshot doc = await collectionReferenceUsers.doc(userId).get();
    
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
        return User.fromMap(data);
    }
  }
  return null;
}

Future<bool> authenticateGoogleUser(String email) async {
  String? userId = await getUserIdByEmail(email);

  if (userId != null) {
    DocumentSnapshot doc = await collectionReferenceUsers.doc(userId).get();

    if (doc.exists) {
      // Obtenemos los datos del documento
      final data = doc.data() as Map<String, dynamic>?;

      // Si no hay datos o isActivate es false, devolvemos false
      final isActivate = data?['isActivate'] as bool? ?? false;
      if (!isActivate) {
        return false;
      }

      // Usuario existe y está activado
      return true;
    }
  }

  return false;
}



  Future<void> acceptUser(User user, String newRole) async {
    String? userId = await getUserIdByEmail(user.mail);
    userId ??= await getUserIdByUsername(user.username);

    if (userId != null) {
      await collectionReferenceUsers.doc(userId).update({
        'rol': newRole,
        'isActivate': true,
      });
    } else {
      throw Exception("Usuario no encontrado");
    }
  }

  Future<String?> getUserRoleByEmail(String email) async {
    String? userId = await getUserIdByEmail(email);

    if (userId != null) {
      DocumentSnapshot doc = await collectionReferenceUsers.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['rol'] as String?;
      }
    }
    return null;
  }

}
