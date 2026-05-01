import 'package:flutter/material.dart';
import 'package:warisanbudaya/question_model.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // Tema Warna
  final Color primaryColor = const Color(0xFF800000);
  final Color accentColor = const Color(0xFFC0A080);
  final Color bgColor = const Color(0xFFFDF5E6);

  int score = 0;
  int streak = 0;
  int currentQuestionIndex = 0;
  int? selectedAnswerIndex;
  bool isAnswered = false;

  final List<Question> _questions = [
    Question(
      questionText: "Dari manakah asal alat musik Angklung?",
      category: "Alat Musik",
      options: ["Jawa Tengah", "Jawa Barat", "Bali", "Sumatera Barat"],
      correctAnswerIndex: 1,
    ),
    Question(
      questionText: "Motif Batik 'Parang Rusak' berasal dari daerah?",
      category: "Batik",
      options: ["Solo", "Pekalongan", "Yogyakarta", "Cirebon"],
      correctAnswerIndex: 2,
    ),
    Question(
      questionText: "Tari 'Saman' merupakan warisan budaya dari?",
      category: "Seni Tari",
      options: ["Aceh", "Sumatera Utara", "Riau", "Lampung"],
      correctAnswerIndex: 0,
    ),
  ];

  void _checkAnswer(int index) {
    if (isAnswered) return;

    setState(() {
      selectedAnswerIndex = index;
      isAnswered = true;

      if (index == _questions[currentQuestionIndex].correctAnswerIndex) {
        score += 10;
        streak++;
      } else {
        streak = 0; // Reset streak jika salah
      }
    });

    // Pindah ke soal berikutnya setelah delay
    Future.delayed(const Duration(seconds: 2), () {
      if (currentQuestionIndex < _questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
          selectedAnswerIndex = null;
          isAnswered = false;
        });
      } else {
        _showResultDialog();
      }
    });
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text("Permainan Selesai!", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: Text("Total Poin: $score\nStreak Tertinggi: $streak"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Keluar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                score = 0;
                streak = 0;
                currentQuestionIndex = 0;
                isAnswered = false;
              });
            },
            child: const Text("Main Lagi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Tebak Warisan"),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Skor & Streak Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statBadge("POIN: $score", Icons.stars, Colors.orange),
                _statBadge("STREAK: $streak", Icons.local_fire_department, Colors.red),
              ],
            ),
            const SizedBox(height: 40),

            // Card Soal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: accentColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: Text(currentQuestion.category, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    currentQuestion.questionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Daftar Pilihan Jawaban
            ...List.generate(currentQuestion.options.length, (index) {
              return _buildOptionButton(index, currentQuestion);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(int index, Question question) {
    Color btnColor = Colors.white;
    if (isAnswered) {
      if (index == question.correctAnswerIndex) {
        btnColor = Colors.green.shade100;
      } else if (index == selectedAnswerIndex) {
        btnColor = Colors.red.shade100;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () => _checkAnswer(index),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isAnswered && index == question.correctAnswerIndex 
                  ? Colors.green 
                  : accentColor.withOpacity(0.5)
            ),
          ),
          child: Text(
            question.options[index],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isAnswered && index == question.correctAnswerIndex ? Colors.green.shade900 : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statBadge(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}