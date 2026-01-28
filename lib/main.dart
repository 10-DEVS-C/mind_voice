import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/service_locator.dart' as di;
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/providers/settings_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/widgets/settings_drawer.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MindVoiceApp());
}

class MindVoiceApp extends StatelessWidget {
  const MindVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<SettingsProvider>()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Mind Voice',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: const [Locale('en', ''), Locale('es', '')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const LoginPage(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(
                    text: 'MIND',
                    style: TextStyle(color: Colors.white),
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
        color: const Color(0xFF020617).withOpacity(0.9),
        border: const Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1),
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

class RecordPage extends StatelessWidget {
  final bool isRecording;
  final String timerText;
  final VoidCallback onToggle;

  const RecordPage({
    super.key,
    required this.isRecording,
    required this.timerText,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            children: [
              Text(
                "Captura tus Ideas",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  // Removed hardcoded color to allow theme
                ),
              ),
              SizedBox(height: 8),
              Text(
                "La IA se encargará del resto",
                style: TextStyle(color: Colors.blueGrey),
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              if (isRecording) ...[
                const _AnimatedWave(size: 200, opacity: 0.2),
                const _AnimatedWave(size: 160, opacity: 0.3),
              ],
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: isRecording
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF7C3AED).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRecording ? Icons.multitrack_audio : Icons.mic_none,
                  size: 60,
                  color: isRecording ? Colors.red : const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                timerText,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w200,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isRecording
                    ? "GRABANDO AUDIO..."
                    : "Toca el botón central para iniciar",
                style: TextStyle(
                  color: isRecording ? Colors.redAccent : Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final audios = [
      {
        "title": "Reunión Estratégica",
        "date": "20 Ene 2026",
        "duration": "12:45",
      },
      {"title": "Idea Proyecto IA", "date": "19 Ene 2026", "duration": "03:20"},
      {
        "title": "Clase de Arquitectura",
        "date": "18 Ene 2026",
        "duration": "45:10",
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tus Audios",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: audios.length,
              itemBuilder: (context, index) {
                final audio = audios[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              audio['title']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${audio['duration']} • ${audio['date']}",
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.blueGrey),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resultados IA",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Último Resumen",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  "La discusión se centró en la optimización de procesos mediante IA. Los puntos clave incluyen la reducción de latencia en la nube.",
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  context,
                  Icons.biotech,
                  "Mind Map",
                  "14 Nodos",
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _infoCard(context, Icons.share, "Compartir", "PDF, MD"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Próximos pasos",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _stepItem("Definir arquitectura de servicios."),
          _stepItem("Revisar costos de AWS Transcribe."),
        ],
      ),
    );
  }

  Widget _infoCard(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            sub,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _stepItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _AnimatedWave extends StatelessWidget {
  final double size;
  final double opacity;
  const _AnimatedWave({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red.withOpacity(opacity),
      ),
    );
  }
}
