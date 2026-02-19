import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../features/library/presentation/pages/library_page.dart';
import '../../../../features/audio_recorder/presentation/pages/record_page.dart';
import '../../../../features/insights/presentation/pages/insights_page.dart';
import '../../../../features/home/presentation/widgets/settings_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _seconds++);
        });
      } else {
        _timer?.cancel();
        _seconds = 0;
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const SettingsDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mic, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(
                    text: 'MIND',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: 'VOICE',
                    style: TextStyle(color: Color(0xFF8B5CF6)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.blueGrey),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const LibraryPage(),
          RecordPage(
            isRecording: _isRecording,
            timerText: _formatTime(_seconds),
            onToggle: _toggleRecording,
          ),
          const InsightsPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.book_outlined, "Audios"),
          _recordButton(),
          _navItem(2, Icons.bar_chart_outlined, "IA Data"),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF8B5CF6) : Colors.blueGrey,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF8B5CF6) : Colors.blueGrey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordButton() {
    return GestureDetector(
      onTap: () {
        if (_currentIndex == 1) {
          _toggleRecording();
        }
        setState(() => _currentIndex = 1);
      },
      child: Container(
        transform: Matrix4.translationValues(0, -20, 0),
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : const Color(0xFF7C3AED),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? Colors.red : const Color(0xFF7C3AED))
                  .withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: const Color(0xFF020617), width: 4),
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
