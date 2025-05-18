import 'package:afa/design/components/pending_user_component.dart';
import 'package:afa/design/components/active_user_component.dart';
import 'package:afa/logic/providers/active_user_provider.dart';
import 'package:afa/logic/providers/pending_user_provider.dart';
import 'package:afa/design/components/side_bar_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _showActiveUsers = false;
  bool _isMenuOpen = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  Future<void> _uploadDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isLoading = true);

        var file = result.files.first;
        String fileName = file.name;

        Reference storageRef =
        FirebaseStorage.instance.ref().child('documents/$fileName');
        UploadTask uploadTask = storageRef.putData(file.bytes!);

        TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('documents').add({
          'title': fileName,
          'fileUrl': downloadUrl,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Documento subido con éxito")),
        );
      }
    } catch (e) {
      print("❌ Error al subir documento: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al subir el documento")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor:
            _isMenuOpen ? const Color.fromARGB(30, 0, 0, 0) : Colors.transparent,
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
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      Icon(
                        Icons.dashboard,
                        color: _isMenuOpen ? Colors.blue[700] : Colors.white,
                        size: 30,
                      ),
                      const SizedBox(width: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final textSize =
                              constraints.maxWidth > 200 ? 24.0 : 20.0;
                          return Text(
                            'Panel de administración',
                            style: TextStyle(
                              color:
                                  _isMenuOpen ? Colors.blue[700] : Colors.white,
                              fontSize: textSize,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          Consumer<PendingUserProvider>(
                            builder: (context, userPendingProvider, child) {
                              final count = userPendingProvider.pendingUsers.length;
                              return count > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : const SizedBox();
                            },
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.person_add_alt_rounded,
                              color: Colors.white),
                          const SizedBox(width: 6),
                          Switch(
                            value: _showActiveUsers,
                            onChanged: (bool value) {
                              setState(() {
                                _showActiveUsers = value;
                              });
                            },
                            activeColor: Colors.white,
                            activeTrackColor: Colors.lightBlue,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.person, color: Colors.white),
                          const SizedBox(width: 6),
                          Consumer<ActiveUserProvider>(
                            builder: (context, activeProvider, child) {
                              final activeCount =
                                  activeProvider.activeUsers.length;
                              return activeCount > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$activeCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : const SizedBox();
                            },
                          ),
                          const SizedBox(width: 10),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              // Se define el contenido del botón según el ancho de la pantalla.
              final Widget content = screenWidth >= 800
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_file, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Subir Documento',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : const Icon(Icons.upload_file, color: Colors.white);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: _uploadDocument,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth >= 800 ? 16 : 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.lightBlue],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: content,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFF063970),
                  theme.brightness == Brightness.dark
                      ? const Color(0xFF121212)
                      : const Color(0xFF66B3FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _showActiveUsers
                          ? const ActiveUserComponent()
                          : const PendingUserComponent(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          if (_isMenuOpen)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SidebarMenu(
                selectedIndex: 1,
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                '© 2025 AFA Andújar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
