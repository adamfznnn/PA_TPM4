import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_page.dart';
import 'culturedetail_page.dart';
import 'angklung_page.dart';
import 'profile_page.dart';
import 'package:warisanbudaya/database.dart';
import 'package:warisanbudaya/services/notification_services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'map_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 🔥 TAMBAHAN: instance notification (biar tidak buat berulang)
  final NotificationService _notificationService = NotificationService();

  final Color primaryColor = const Color(0xFF800000);
  final Color accentColor = const Color(0xFFC0A080);
  final Color bgColor = const Color(0xFFFDF5E6);
  final Color cardWhite = Colors.white;

  String _fullName = "Pengguna";
  String _greeting = "Selamat Datang";
  String _selectedCategory = "Semua";
  String? _profileImagePath;

  List<String> _categories = [];
  List<Map<String, dynamic>> _collections = [];
  List<Map<String, dynamic>> _filteredCollections = [];

  bool _isLoadingCategories = true;
  bool _isLoadingCollections = true;

  @override
  void initState() {
    super.initState();
    _initAll(); // 🔥 dirapikan
  }

  // 🔥 INIT TERPUSAT
  Future<void> _initAll() async {
    await _notificationService.initNotification();
    await _refreshData();
    _updateGreeting();
    await _fetchCategories();
    await _fetchCollections();
  }

  Future<void> _openMap(double lat, double lng, String label) async {
    final Uri googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng($label)",
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak bisa membuka Google Maps")),
      );
    }
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('fullName') ?? "Pengguna";
      _profileImagePath = prefs.getString('profile_image');
    });
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      _greeting = "Selamat pagi";
    } else if (hour < 15) {
      _greeting = "Selamat siang";
    } else if (hour < 18) {
      _greeting = "Selamat sore";
    } else {
      _greeting = "Selamat malam";
    }
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    final cats = await DbHelper().getCategories();
    setState(() {
      _categories = ["Semua", ...cats.where((c) => c != "Semua")];
      _isLoadingCategories = false;
    });
  }

  Future<void> _fetchCollections({String category = 'Semua'}) async {
    setState(() => _isLoadingCollections = true);
    final data = await DbHelper().getCollections(category: category);
    setState(() {
      _collections = data;
      _filteredCollections = data;
      _isLoadingCollections = false;
    });
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredCollections = _collections.where((item) {
        final name = item['name'].toString().toLowerCase();
        final loc = item['location'].toString().toLowerCase();
        return name.contains(query.toLowerCase()) ||
            loc.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _onCategorySelected(String category) {
    setState(() => _selectedCategory = category);
    _fetchCollections(category: category);
  }

  // 🔔 🔥 PERBAIKAN NOTIF (dipisah jadi function)
  Future<void> _showNotification() async {
    final facts = [
      "Candi Borobudur memiliki 2.672 panel relief 🏛️",
      "Batik diakui UNESCO sejak 2009 🎨",
      "Angklung diakui UNESCO sejak 2010 🎶",
    ];

    facts.shuffle();

    await _notificationService.showNotification(
      id: 1,
      title: "Wawasan Budaya 🇮🇩",
      body: facts.first,
      payload: "detail_budaya",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Notifikasi berhasil dikirim!"),
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: () async {
            await _initAll();
          },
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

  // ================= HEADER =================
  Widget _buildHeader() {
    String initial = _fullName.trim().isNotEmpty
        ? _fullName.trim()[0].toUpperCase()
        : "U";

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
              // 🔥 ICON BUTTON SUDAH DIPERBAIKI
              IconButton(
                icon: Icon(
                  Icons.notifications_active_outlined,
                  color: primaryColor,
                  size: 28,
                ),
                onPressed: _showNotification,
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  ).then((_) => _refreshData());
                },
                child: CircleAvatar(
                  backgroundColor: accentColor.withOpacity(0.2),
                  radius: 18,
                  backgroundImage:
                      (_profileImagePath != null &&
                          File(_profileImagePath!).existsSync())
                      ? FileImage(File(_profileImagePath!))
                      : null,
                  child:
                      (_profileImagePath == null ||
                          !File(_profileImagePath!).existsSync())
                      ? Text(initial)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= SEARCH =================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        onChanged: _filterSearch,
        decoration: InputDecoration(
          hintText: "Cari batik, tari, kuliner...",
          prefixIcon: Icon(Icons.search, color: accentColor),
          filled: true,
          fillColor: cardWhite,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ================= CATEGORIES =================
  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                return GestureDetector(
                  onTap: () => _onCategorySelected(cat),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: _selectedCategory == cat
                          ? primaryColor
                          : cardWhite,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: _selectedCategory == cat
                              ? Colors.white
                              : primaryColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ================= COLLECTIONS =================
  Widget _buildCollections() {
    if (_isLoadingCollections) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredCollections.isEmpty) {
      return const Center(child: Text("Tidak ada data"));
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filteredCollections.length,
        itemBuilder: (context, i) {
          final item = _filteredCollections[i];
          return _collectionCard(item);
        },
      ),
    );
  }

  Widget _collectionCard(Map<String, dynamic> item) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CultureDetailPage(
            itemName: item['name'],
            category: item['category'],
            location: item['location'],
            description: item['description'],
            imagePath: item['image_path'],
            colorHex: item['color_hex'],
          ),
        ),
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.all(8),
        color: cardWhite,
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                item['image_path'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image),
              ),
            ),
            Text(item['name']),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardWhite, bgColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.2)),
            ),
            child: Icon(Icons.auto_awesome, color: primaryColor, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    "Pilihan Hari Ini",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
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

  Widget _cardColorFallback(Color color, String label) {
    return Container(
      width: double.infinity,
      color: color.withOpacity(0.3),
      child: Center(child: Icon(Icons.image_outlined, color: color, size: 30)),
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
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 28,
              ),
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
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFF1D9E75),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        _sectionHeader("Rekomendasi Museum", hasAction: true),
        _locationItem(
          "Museum Sonobudoyo",
          "Museum • 1.2 km",
          Icons.museum,
          -7.8025,
          110.3638,
        ),

        _locationItem(
          "Keraton Yogyakarta",
          "Istana Sejarah • 2.1 km",
          Icons.fort,
          -7.8052,
          110.3642,
        ),
      ],
    );
  }

  Widget _locationItem(
    String title,
    String sub,
    IconData icon,
    double lat,
    double lng,
  ) {
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
      subtitle: Text(
        sub,
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),

      // 🔥 INI KUNCINYA
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MapPage(destination: LatLng(lat, lng), placeName: title),
          ),
        );
      },
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(15),
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
            GestureDetector(
              onTap: () {},
              child: Text(
                "Lihat Semua",
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
