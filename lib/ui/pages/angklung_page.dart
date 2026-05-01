import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';

class AngklungPage extends StatefulWidget {
  const AngklungPage({super.key});

  @override
  State<AngklungPage> createState() => _AngklungPageState();
}

class _AngklungPageState extends State<AngklungPage> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  String _activeNote = 'A1';
  final double _threshold = 1.5;
  bool _canPlay = true;
  final Duration _cooldown = const Duration(milliseconds: 400);
  final List<String> _notes = ['A1', 'A2', 'A3'];

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event) {
      if ((event.y.abs() > _threshold || event.x.abs() > _threshold) && _canPlay) {
        _playNote(_activeNote);
      }
    });
  }

  Future<void> _playNote(String note) async {
    _canPlay = false;
    await _player.play(AssetSource('sounds/$note.mp3'));
    Future.delayed(_cooldown, () {
      if (mounted) setState(() => _canPlay = true);
    });
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Angklung Digital')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Pilih Nada:',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: _notes.map((note) {
                  final isActive = note == _activeNote;
                  return GestureDetector(
                    onTap: () => setState(() => _activeNote = note),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.orange : Colors.brown.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive ? Colors.deepOrange : Colors.brown,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        note.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : Colors.brown.shade800,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              Icon(
                _canPlay ? Icons.music_note : Icons.music_off,
                size: 64,
                color: _canPlay ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                _canPlay ? 'Goyangkan HP untuk berbunyi!' : 'Sedang berbunyi...',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}