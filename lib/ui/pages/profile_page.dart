import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color primaryColor = const Color(0xFF800000);
  final Color bgColor = const Color(0xFFFDF5E6);

  String _name = "";
  String _username = "";
  File? _imageFile;

  final ImagePicker _picker = ImagePicker();

  // 🔥 LOAD DATA USER + FOTO
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    String? imagePath = prefs.getString('profile_image');

    setState(() {
      _name = prefs.getString('fullName') ?? "Tidak diketahui";
      _username = prefs.getString('username') ?? "-";

      if (imagePath != null && imagePath.isNotEmpty) {
        _imageFile = File(imagePath);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 📷 PILIH FOTO & SIMPAN PATH
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('profile_image', pickedFile.path);

        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // ✏️ EDIT NAMA
  void _showEditProfileDialog() {
    TextEditingController nameController =
        TextEditingController(text: _name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "Edit Profil",
          style: TextStyle(color: primaryColor),
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Nama Lengkap",
            icon: Icon(Icons.person),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();

              await prefs.setString('fullName', nameController.text);

              setState(() {
                _name = nameController.text;
              });

              Navigator.pop(context);
            },
            child: const Text("Simpan",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🚪 LOGOUT (TIDAK HAPUS FOTO)
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('isLoggedIn');
    await prefs.remove('username');
    await prefs.remove('fullName');
    // ❌ JANGAN HAPUS profile_image

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Profil Pengguna"),
        backgroundColor: primaryColor,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.white),
            onPressed: _showEditProfileDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 4),
                        ),
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : const AssetImage(
                                      'assets/profile_adam.jpg')
                                  as ImageProvider,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.orangeAccent,
                            child: Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Text(
                    _name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Username: $_username",
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "Aplikasi Warisan Nusantara membantu mengenal budaya Indonesia 🇮🇩",
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}