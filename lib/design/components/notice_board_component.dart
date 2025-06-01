import 'package:afa/logic/services/documents_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticeBoardComponent extends StatefulWidget {
  final ScrollController? scrollController;
  final String rol;
  const NoticeBoardComponent({this.scrollController,required this.rol, super.key});

  @override
  State<NoticeBoardComponent> createState() => _NoticeBoardComponentState();
}

class _NoticeBoardComponentState extends State<NoticeBoardComponent> {
  final DocumentService _documentService = DocumentService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _documents = [];
  
  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _uploadDocument() async 
  {
    final success = await _documentService.uploadDocument();
    if (success) {
      _loadDocuments();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documento subido correctamente.')),
      );
    }
  }

  Future<void> _confirmDelete(String title, String url) async 
  {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      title: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFE53935)], // Rojo degradado
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                '¿Eliminar documento?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
      content: const Text(
        'Esta acción no se puede deshacer.',
        style: TextStyle(color: Color(0xFF2D3748)),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[800],
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.white.withOpacity(0.2);
                      }
                      return null;
                    }),
                  ),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    )
    );


    if (confirmed == true) {
      try {
        await _documentService.deleteDocument(title, url);
        _loadDocuments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento eliminado.')),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el documento.')),
        );
      }
    }
  }

  Future<void> _loadDocuments() async {
    try {
      final docs = await _documentService.getDocuments();
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar documentos: $e')),
      );
    }
  }

  Future<void> _launchFile(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el archivo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isAdmin = widget.rol == 'Administrador';


    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Encabezado degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF063970), Color(0xFF66B3FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.feed, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tablón de Anuncios',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    tooltip: 'Subir documento',
                    icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
                    onPressed: _uploadDocument,
                  ),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista de documentos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _documents.isEmpty
                    ? const Center(
                        child: Text(
                          "No hay documentos disponibles.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF718096),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: widget.scrollController,
                        itemCount: _documents.length,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemBuilder: (context, index) {
                          final doc = _documents[index];
                          return _buildDocumentItem(
                              doc["title"], doc["fileUrl"], doc["uploadDate"], isAdmin);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String title, String fileUrl, Timestamp date, bool isAdmin) {
  final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date.toDate());

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      leading: const Icon(Icons.insert_drive_file, color: Color(0xFF3182CE)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF3182CE)),
            onPressed: () => _launchFile(fileUrl),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              tooltip: "Eliminar",
              onPressed: () => _confirmDelete(title, fileUrl),
            ),
        ],
      ),
    ),
  );
}
}
