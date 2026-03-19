import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../../features/library/presentation/pages/library_page.dart';
import '../../../../features/audio_recorder/presentation/pages/record_page.dart';
import '../../../../features/insights/presentation/pages/insights_page.dart';
import '../../../../features/home/presentation/widgets/settings_drawer.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../features/audio_recorder/presentation/providers/audio_recorder_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    if (mounted) setState(() => _seconds = 0);
  }

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authUser = context.watch<AuthProvider>().user;
    final audioProvider = context.watch<AudioRecorderProvider>();
    final isRecording = audioProvider.isRecording;
    final userId = context.watch<AuthProvider>().user?.id;

    // Sync timer with provider state
    if (isRecording && (_timer == null || !_timer!.isActive)) {
      _startTimer();
    } else if (!isRecording && _timer != null && _timer!.isActive) {
      _stopTimer();
    }

    return Scaffold(
      endDrawer: const SettingsDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            isDarkMode ? AppAssets.logo1 : AppAssets.logo2,
            height: 56,
            width: 96,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Scaffold.of(context).openEndDrawer(),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    (authUser?.name.isNotEmpty == true
                            ? authUser!.name
                            : (authUser?.username.isNotEmpty == true
                                ? authUser!.username
                                : 'M'))
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  size: 30),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? const [Color(0xFF0B0514), Color(0xFF140C20)]
                  : const [Color(0xFFF4F7FB), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: IndexedStack(
            index: _currentIndex,
            children: [
              LibraryPage(onNavigateToInsights: () => _handleTabChange(2)),
              RecordPage(
                isRecording: isRecording,
                timerText: _formatTime(_seconds),
                onToggle: () {
                  if (isRecording) {
                    if (userId != null) {
                      context.read<AudioRecorderProvider>().stopRecording(userId);
                    }
                  } else {
                    context.read<AudioRecorderProvider>().startRecording();
                  }
                },
              ),
              const InsightsPage(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: _buildBottomNav(isRecording, userId, l10n),
      ),
    );
  }

  Widget _buildBottomNav(
    bool isRecording,
    String? userId,
    AppLocalizations l10n,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBackground : Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.7),
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(0, Icons.book_outlined, l10n.translate('homeTabLibrary')),
          _recordButton(isRecording, userId),
          _navItem(2, Icons.bar_chart_outlined, l10n.translate('homeTabInsights')),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _handleTabChange(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isActive
                  ? const Color(0xFF6D28D9).withOpacity(0.14)
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isActive ? 1.12 : 1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: Icon(
                      icon,
                      color: isActive
                          ? const Color(0xFF6D28D9)
                          : Theme.of(context).textTheme.bodySmall?.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF6D28D9)
                          : Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: isActive ? 10.5 : 9.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    ),
                    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _recordButton(bool isRecording, String? userId) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final navBackground = isDarkMode
        ? AppColors.darkBackground
        : Theme.of(context).cardColor;

    return GestureDetector(
      onTap: () {
        if (_currentIndex != 1) {
          _handleTabChange(1);
          return;
        }
        if (isRecording) {
          if (userId != null) {
            context.read<AudioRecorderProvider>().stopRecording(userId);
          }
        } else {
          context.read<AudioRecorderProvider>().startRecording();
        }
      },
      child: Container(
        transform: Matrix4.translationValues(0, -8, 0),
        child: AnimatedScale(
          scale: isRecording ? 1.05 : 1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: navBackground,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isRecording
                      ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                      : [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isRecording
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF6D28D9))
                        .withOpacity(0.45),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: navBackground,
                  width: 2,
                ),
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
