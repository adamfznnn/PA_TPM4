import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_page.dart';
import 'culturedetail_page.dart';
import 'angklung_page.dart';
import 'profile_page.dart'; // Pastikan ini diimport
import 'package:warisanbudaya/database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Palet Warna Utama
  final Color primaryColor = const Color(0xFF800000);
  final Color accentColor = const Color(0xFFC0A080);
  final Color bgColor = const Color(0xFFFDF5E6);
  final Color cardWhite = Colors.white;

  // State
  String _fullName = "Pengguna";
  String _greeting = "Selamat Datang";
  String _selectedCategory = "Semua";
  String? _profileImagePath; // State untuk path foto

  // Data dari SQLite
  List<String> _categories = [];
  List<Map<String, dynamic>> _collections = [];

  // Status loading
  bool _isLoadingCategories = true;
  bool _isLoadingCollections = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _updateGreeting();
    _fetchCategories();
    _fetchCollections();
  }

  // Fungsi untuk refresh data (dipanggil di initState & saat balik dari profil)
  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('fullName') ?? "Pengguna";
      _profileImagePath = prefs.getString('profile_image');
    });
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour >= 5 && hour < 11) {
        _greeting = "Selamat pagi";
      } else if (hour >= 11 && hour < 15) {
        _greeting = "Selamat siang";
      } else if (hour >= 15 && hour < 18) {
        _greeting = "Selamat sore";
      } else {
        _greeting = "Selamat malam";
      }
    });
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    final cats = await DbHelper().getCategories();
    setState(() {
      _categories = cats;
      _isLoadingCategories = false;
    });
  }

  Future<void> _fetchCollections({String category = 'Semua'}) async {
    setState(() => _isLoadingCollections = true);
    final data = await DbHelper().getCollections(category: category);
    setState(() {
      _collections = data;
      _isLoadingCollections = false;
    });
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    _fetchCollections(category: category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSearchBar(),
                _buildCategories(),
                _buildFeaturedSection(),
                _buildCollections(),
                _buildAngklungBanner(),
                _buildLocationSection(),
                _buildAIChatBar(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widget Components ─────────────────────────────────────

  Widget _buildHeader() {
    String initial = _fullName.isNotEmpty ? _fullName[0].toUpperCase() : "U";
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$_greeting, $_fullName",
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Jelajahi warisan budaya hari ini",
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.notifications_none, color: primaryColor),
              const SizedBox(width: 15),
              // Bagian Profil yang bisa diklik
              GestureDetector(
                onTap: () {
                  // Navigasi ke ProfilePage dan refresh saat kembali
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  ).then((_) => _refreshData()); 
                },
                child: CircleAvatar(
                  backgroundColor: accentColor,
                  radius: 18,
                  backgroundImage: (_profileImagePath != null && _profileImagePath!.isNotEmpty)
                      ? FileImage(File(_profileImagePath!))
                      : null,
                  child: (_profileImagePath == null || _profileImagePath!.isEmpty)
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Cari batik, tari, kuliner...",
          hintStyle: const TextStyle(fontSize: 14),
          prefixIcon: Icon(Icons.search, color: accentColor),
          filled: true,
          fillColor: cardWhite,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            "Kategori Budaya",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 40,
          child: _isLoadingCategories
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: 5,
                  itemBuilder: (_, __) => Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final bool isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => _onCategorySelected(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : cardWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : accentColor.withOpacity(0.3),
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Icon(Icons.grid_4x4, color: primaryColor, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    "Pilihan Hari Ini",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Motif Parang Rusak",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text(
                  "Pelajari filosofi kepemimpinan Jawa",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          _selectedCategory == "Semua"
              ? "Jelajahi Koleksi"
              : "Koleksi $_selectedCategory",
        ),
        if (_isLoadingCollections)
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: 3,
              itemBuilder: (_, __) => Container(
                width: 130,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          )
        else if (_collections.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: Text(
                "Belum ada koleksi untuk kategori ini.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _collections.length,
              itemBuilder: (context, i) {
                final item = _collections[i];
                final color = Color(
                  int.parse('FF${item['color_hex']}', radix: 16),
                );
                return _collectionCard(
                  item['category'],
                  item['name'],
                  item['location'],
                  color,
                  item['image_path'] ?? '',
                  item['color_hex'] ?? 'FFF5E1',
                  item['description'] ?? '',
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _collectionCard(
    String cat,
    String name,
    String loc,
    Color headerColor,
    String imagePath,
    String colorHex,
    String description,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CultureDetailPage(
              itemName: name,
              category: cat,
              location: loc,
              description: description,
              imagePath: imagePath,
              colorHex: colorHex,
            ),
          ),
        );
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: accentColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: imagePath.isNotEmpty
                    ? Image.asset(
                        imagePath,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _cardColorFallback(headerColor, cat),
                      )
                    : _cardColorFallback(headerColor, cat),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    loc,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardColorFallback(Color color, String label) {
    return Container(
      width: double.infinity,
      color: color,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAngklungBanner() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AngklungPage()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF1D9E75).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.music_note, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Main Angklung Digital",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    "Guncang HP-mu untuk nada angklung!",
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1D9E75)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        _sectionHeader("Terdekat Darimu", hasAction: true),
        _locationItem("Museum Sonobudoyo", "Museum • 1.2 km", Icons.museum),
        _locationItem("Pasar Beringharjo", "Pusat Batik • 2.5 km", Icons.shopping_bag),
      ],
    );
  }

  Widget _locationItem(String title, String sub, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cardWhite,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 18),
    );
  }

  Widget _buildAIChatBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: accentColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: accentColor, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Tanya pakar AI tentang budaya...",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "TANYA AI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {bool hasAction = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (hasAction)
            Text(
              "Lihat Semua",
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}