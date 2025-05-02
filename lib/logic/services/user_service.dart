import 'package:afa/logic/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService 
{
  final CollectionReference collectionReferenceUsers;

  UserService() : collectionReferenceUsers = FirebaseFirestore.instance.collection('usuarios');

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

  Future<List<User>> getUsers() async {
    List<User> usersRegister = [];
    QuerySnapshot queryUsers = await collectionReferenceUsers.get();

    for (var documento in queryUsers.docs) {
      final data = documento.data() as Map<String, dynamic>;
      final user = User.fromMap(data);
      usersRegister.add(user);
    }

    return usersRegister;
  }

  Future<List<User>> getUsersByRol(String rol) async 
  {
      List<User> usersRol = [];
      QuerySnapshot querySnapshot = await collectionReferenceUsers
          .where('rol', isEqualTo: rol)
          .get();
    for (var documento in querySnapshot.docs) {
      final data = documento.data() as Map<String, dynamic>;
      final user = User.fromMap(data);
      usersRol.add(user);
      print("rule $user");
    }
    print(usersRol.first.name);
    return usersRol;
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
        'fcmToken': user.fcmToken
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
