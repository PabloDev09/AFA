import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  final bool _isLoading = false;
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('documents').get();
      setState(() {
        _documents = querySnapshot.docs
            .map((doc) => {"title": doc["title"], "fileUrl": doc["fileUrl"]})
            .toList();
      });
    } catch (e) {
      print("❌ Error al cargar documentos: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tablón de Anuncios")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📂 Compartición de Documentación",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            Expanded(
              child: ListView(
                children: _documents.map((doc) => _buildDocumentItem(doc["title"], doc["fileUrl"])).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(String title, String fileUrl) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton(
          icon: const Icon(Icons.download, color: Colors.blue),
          onPressed: () => print("Descargando $fileUrl"),
        ),
      ),
    );
  }
}
