import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CultureDetailPage extends StatefulWidget {
  final String itemName;
  final String category;
  final String location;
  final String description;
  final String imagePath;
  final String colorHex;

  const CultureDetailPage({
    super.key,
    required this.itemName,
    required this.category,
    required this.location,
    required this.description,
    this.imagePath = '',
    this.colorHex = 'FFF5E1',
  });

  @override
  _CultureDetailPageState createState() => _CultureDetailPageState();
}

class _CultureDetailPageState extends State<CultureDetailPage> {
  bool _isLoadingAI = false;
  bool _aiLoaded = false;
  String _aiContent = "";

  final Color primaryColor = const Color(0xFF800000);
  final Color accentColor = const Color(0xFFC0A080);
  final Color bgColor = const Color(0xFFFDF5E6);

  // AI dipanggil hanya saat user tap tombol "Pelajari Lebih Dalam"
  Future<void> _fetchAIInfo() async {
    setState(() => _isLoadingAI = true);
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.get('GEMINI_API_KEY'),
      );

      final prompt =
          "Jelaskan secara mendalam tentang warisan budaya '${widget.itemName}' dari ${widget.location} "
          "dalam 3 bagian: Sejarah, Filosofi, dan Cara Melestarikannya. "
          "Gunakan format yang rapi dan bahasa Indonesia yang santun.";

      final response = await model.generateContent([Content.text(prompt)]);

      if (mounted) {
        setState(() {
          _aiContent = response.text ?? "Gagal mendapatkan informasi.";
          _isLoadingAI = false;
          _aiLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiContent = "Terjadi kesalahan: $e";
          _isLoadingAI = false;
          _aiLoaded = true;
        });
        debugPrint("DEBUG_ERROR_GEMINI: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = Color(
      int.parse('FF${widget.colorHex}', radix: 16),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.itemName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                ),
              ),
              background: widget.imagePath.isNotEmpty
                  ? Image.asset(
                      widget.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _headerColorFallback(headerColor),
                    )
                  : _headerColorFallback(headerColor),
            ),
          ),

          // ── Body Content ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Kategori + Lokasi
                  Row(
                    children: [
                      _badge(widget.category, primaryColor),
                      const SizedBox(width: 8),
                      _badge("📍 ${widget.location}", accentColor),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nama
                  Text(
                    widget.itemName,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Deskripsi dari DB (tampil langsung / instant)
                  _infoCard(
                    icon: Icons.info_outline,
                    title: "Tentang",
                    content: widget.description.isNotEmpty
                        ? widget.description
                        : "Tidak ada deskripsi tersedia.",
                  ),
                  const SizedBox(height: 20),

                  // ── Tombol / Area AI ─────────────────────
                  if (!_aiLoaded && !_isLoadingAI)
                    _buildAIButton()
                  else if (_isLoadingAI)
                    _buildAILoading()
                  else
                    _buildAIContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub Widgets ───────────────────────────────────────────

  Widget _headerColorFallback(Color color) {
    return Container(
      color: color,
      child: Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: Colors.white54, size: 48),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // Tombol untuk trigger AI
  Widget _buildAIButton() {
    return GestureDetector(
      onTap: _fetchAIInfo,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, accentColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              "Pelajari Lebih Dalam dengan AI",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading indicator saat AI sedang generate
  Widget _buildAILoading() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 12),
          Text(
            "Pakar AI sedang menyiapkan informasi...",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Hasil konten dari AI
  Widget _buildAIContent() {
    return _infoCard(
      icon: Icons.auto_awesome,
      title: "Penjelasan Mendalam (AI)",
      content: _aiContent,
    );
  }
}