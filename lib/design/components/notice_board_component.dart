import 'package:afa/logic/services/documents_service.dart';
import 'package:flutter/material.dart';
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
        title: const Text("¿Eliminar documento?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        ],
      ),
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
                const Icon(Icons.announcement, color: Colors.white),
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
                              doc["title"], doc["fileUrl"], isAdmin);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String title, String fileUrl, bool isAdmin) {
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
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
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
