import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  final String _apiKey = dotenv.get('GEMINI_API_KEY');
  late final GenerativeModel _model;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastShakeTime = DateTime.now();
  final Random _random = Random();

  final List<String> _topikBudaya = [
    "Kuliner Tradisional",
    "Tarian Daerah",
    "Alat Musik",
    "Senjata Tradisional",
    "Candi/Prasasti",
    "Wastra/Kain",
    "Bahasa Daerah",
  ];

  final List<String> _faktaOffline = [
    "Tahukah kamu? Rendang dinobatkan sebagai salah satu makanan terenak di dunia versi CNN.",
    "Tahukah kamu? Candi Borobudur dibangun dengan sistem penguncian batu tanpa semen sama sekali.",
    "Tahukah kamu? Indonesia memiliki lebih dari 700 bahasa daerah yang aktif digunakan.",
    "Tahukah kamu? Angklung telah diakui UNESCO sebagai Warisan Budaya Takbenda sejak 2010.",
    "Tahukah kamu? Tari Saman dari Aceh melibatkan gerakan tepukan dada dan tangan yang sangat sinkron.",
  ];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

    _messages.add({
      "text":
          "Halo! Saya asisten WarisanNusantara. Tanyakan apapun, atau guncangkan HP-mu untuk mendapatkan fakta unik!",
      "isUser": false,
      "isError": false, // Flag baru untuk status error
      "time": DateTime.now(),
    });

    _accelerometerSubscription = accelerometerEvents.listen((
      AccelerometerEvent event,
    ) {
      if (event.x.abs() > 15 || event.y.abs() > 15 || event.z.abs() > 15) {
        _handleShake();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleShake() {
    if (DateTime.now().difference(_lastShakeTime).inSeconds < 3) return;
    _lastShakeTime = DateTime.now();
    String topikPilihan = _topikBudaya[_random.nextInt(_topikBudaya.length)];
    _sendAutoFakta(topikPilihan);
  }

  void _sendAutoFakta(String topik) async {
    setState(() {
      _isTyping = true;
      _messages.add({
        "text": "✨ Mengambil fakta tentang $topik...",
        "isUser": false,
        "isError": false,
        "time": DateTime.now(),
      });
    });
    _scrollToBottom();

    try {
      final content = [
        Content.text(
          "Berikan satu fakta unik singkat tentang $topik Indonesia. Mulailah dengan kata 'Tahukah kamu?'",
        ),
      ];
      final response = await _model.generateContent(content);

      setState(() {
        _isTyping = false;
        _messages.removeLast();
        _messages.add({
          "text":
              response.text ??
              _faktaOffline[_random.nextInt(_faktaOffline.length)],
          "isUser": false,
          "isError": response.text == null,
          "time": DateTime.now(),
        });
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.removeLast();
        _messages.add({
          "text": "Gagal mengambil fakta otomatis: ${e.toString()}",
          "isUser": false,
          "isError": true, // Set error ke true
          "time": DateTime.now(),
        });
      });
    }
    _scrollToBottom();
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    String userText = _controller.text;

    setState(() {
      _messages.add({
        "text": userText,
        "isUser": true,
        "isError": false,
        "time": DateTime.now(),
      });
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final content = [
        Content.text(
          "Kamu adalah pakar budaya Indonesia. Jawab singkat: $userText",
        ),
      ];
      final response = await _model.generateContent(content);

      setState(() {
        _isTyping = false;
        if (response.text == null) throw Exception("Respon kosong dari AI");
        _messages.add({
          "text": response.text,
          "isUser": false,
          "isError": false,
          "time": DateTime.now(),
        });
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          "text": "Terjadi kesalahan: ${e.toString()}",
          "isUser": false,
          "isError": true, // Menandai bubble sebagai error
          "time": DateTime.now(),
        });
      });
    }
    _scrollToBottom();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      appBar: AppBar(
        elevation: 2,
        toolbarHeight: 70,
        title: Column(
          children: const [
            Text(
              "Pakar Budaya AI",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            Text(
              "Online • WarisanNusantara",
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF800000),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildChatBubble(_messages[index]),
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF800000),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Mencari info...",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    bool isUser = msg['isUser'];
    bool isError = msg['isError'] ?? false; // Ambil status error

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              // Jika error, warna background menjadi merah muda pucat
              color: isError
                  ? Colors.red[50]
                  : (isUser ? const Color(0xFF800000) : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(15),
                topRight: const Radius.circular(15),
                bottomLeft: Radius.circular(isUser ? 15 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 15),
              ),
              border: isError
                  ? Border.all(color: Colors.red[200]!)
                  : null, // Tambah border merah jika error
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isError)
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 18,
                  ), // Icon error
                if (isError) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    msg['text'],
                    style: TextStyle(
                      color: isError
                          ? Colors.red[900]
                          : (isUser ? Colors.white : Colors.black87),
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(
              "${msg['time']?.hour ?? 0}:${(msg['time']?.minute ?? 0).toString().padLeft(2, '0')}",
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20, top: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: "Tanya budaya kita...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF800000),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
