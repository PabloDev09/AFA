import 'package:afa/logic/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  UserService();

  Future<void> createUser(User userRegister) async {
    CollectionReference collectionReferenceUsers = db.collection('usuarios');

    await collectionReferenceUsers.add({
      'mail': userRegister.mail,
      'username': userRegister.username,
      'password': userRegister.password,
      'name': userRegister.name,
      'surnames': userRegister.surnames,
      'address': userRegister.address,
      'phoneNumber': userRegister.phoneNumber,
      'rol': userRegister.rol,
      'isActivate': userRegister.isActivate
    });
  }

  Future<List<User>> getUsers() async {
    List<User> usersRegister = [];
    CollectionReference collectionReferenceUsers = db.collection('usuarios');
    QuerySnapshot queryUsers = await collectionReferenceUsers.get();

    for (var documento in queryUsers.docs) {
      final data = documento.data() as Map<String, dynamic>;
      final user = User.fromMap(data);
      usersRegister.add(user);
    }

    return usersRegister;
  }

  // Método privado que busca el usuario por email
  Future<String?> getUserIdByEmail(String email) async {
    CollectionReference collectionReferenceUsers = db.collection('usuarios');
    QuerySnapshot queryByEmail = await collectionReferenceUsers
        .where('mail', isEqualTo: email)
        .limit(1)
        .get();
    if (queryByEmail.docs.isNotEmpty) {
      return queryByEmail.docs.first.id;
    }
    return null;
  }

  // Método privado que busca el usuario por username
  Future<String?> getUserIdByUsername(String username) async {
    CollectionReference collectionReferenceUsers = db.collection('usuarios');
    QuerySnapshot queryByUsername = await collectionReferenceUsers
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (queryByUsername.docs.isNotEmpty) {
      return queryByUsername.docs.first.id;
    }
    return null;
  }

  Future<void> updateUser(User user) async {
    // Primero se intenta obtener el id por email; si no se encuentra, se busca por username
    String? userId = await getUserIdByEmail(user.mail);
    userId ??= await getUserIdByUsername(user.username);

    if (userId != null) {
      CollectionReference collectionReferenceUsers = db.collection('usuarios');
      await collectionReferenceUsers.doc(userId).update({
        'mail': user.mail,
        'username': user.username,
        'password': user.password,
        'name': user.name,
        'surnames': user.surnames,
        'address': user.address,
        'phoneNumber': user.phoneNumber,
        'rol': user.rol,
        'isActivate': user.isActivate
      });
    } else {
      throw Exception("Usuario no encontrado");
    }
  }

  Future<void> deleteUserByEmailOrUsername(String email, String username) async {
    // Primero se intenta obtener el id por email; si no se encuentra, se busca por username
    String? userId = await getUserIdByEmail(email);
    userId ??= await getUserIdByUsername(username);

    if (userId != null) {
      CollectionReference collectionReferenceUsers = db.collection('usuarios');
      await collectionReferenceUsers.doc(userId).delete();
    } else {
      throw Exception("Usuario no encontrado");
    }
  }

  Future<bool> authenticateUser(String email, String username, String password) async {
    // Se busca el usuario por email; si no se encuentra, se intenta por username
    String? userId = await getUserIdByEmail(email);
    userId ??= await getUserIdByUsername(username);

    if (userId != null) {
      DocumentSnapshot doc = await db.collection('usuarios').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['password'] == password) {
          return true;
        }
      }
    }
    return false;
  }
}
