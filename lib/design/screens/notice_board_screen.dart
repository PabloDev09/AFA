import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:afa/design/components/side_bar_menu.dart';

class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  final bool _isLoading = false;
  List<Map<String, dynamic>> _documents = [];
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

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
      appBar: AppBar(
    backgroundColor: _isMenuOpen ? const Color.fromARGB(30, 0, 0, 0) : Colors.blue[300],
    elevation: 0,
    title: Row(
      children: [
        IconButton(
          icon: Icon(
            _isMenuOpen ? Icons.close : Icons.menu,
            color: _isMenuOpen ? Colors.blue[700] : Colors.white,
          ),
          onPressed: _toggleMenu,
        ),
        const SizedBox(width: 8),
        const Text(
          'Tablon de Anuncios',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    ),
  ),
      body: Stack(
        children: [
          Padding(
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
          // Capa oscura si el menú está abierto
      if (_isMenuOpen)
        Positioned.fill(
          child: GestureDetector(
            onTap: _toggleMenu,
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        ),

      // Sidebar visible
      if (_isMenuOpen)
         const Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: SidebarMenu(selectedIndex: 0),
        ),
        ],
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
