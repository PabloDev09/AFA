import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
    final _collection = FirebaseFirestore.instance.collection('documentos');

  Future<List<Map<String, dynamic>>> getDocuments() async {
    try {
      final snapshot = await _collection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          "title": data["title"] ?? "Sin título",
          "fileUrl": data["fileUrl"] ?? "",
          "uploadDate": data["uploadDate"] ?? "",
        };
      }).toList();
    } catch (e) {
      print("❌ Error en DocumentService.getDocuments: $e");
      rethrow;
    }
  }

  Future<bool> uploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final String fileName = file.name;

        final Reference storageRef = _storage.ref().child('documentos/$fileName');
        final UploadTask uploadTask = storageRef.putData(file.bytes!);

        final TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        final DateTime uploadDate = DateTime.now();

        await _firestore.collection('documentos').add({
          'title': fileName,
          'fileUrl': downloadUrl,
          'uploadDate': uploadDate,
        });

        return true;
      }

      return false;
    } catch (e) {
      print("❌ Error al subir documento: $e");
      return false;
    }
  }

  Future<void> deleteDocument(String title, String fileUrl) async {
    try {
      // Eliminar el archivo de Firebase Storage
      final Reference storageRef = _storage.refFromURL(fileUrl);
      await storageRef.delete();

      // Eliminar el documento de Firestore
      final query = await _collection.where('title', isEqualTo: title).where('fileUrl', isEqualTo: fileUrl).get();
      for (var doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print("❌ Error al borrar documento: $e");
      rethrow;
    }
  }
}