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

        await _firestore.collection('documentos').add({
          'title': fileName,
          'fileUrl': downloadUrl,
        });

        return true;
      }

      return false;
    } catch (e) {
      print("❌ Error al subir documento: $e");
      return false;
    }
  }
}