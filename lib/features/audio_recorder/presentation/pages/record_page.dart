import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

class RecordPage extends StatelessWidget {
  final bool isRecording;
  final String timerText;
  final VoidCallback onToggle;
  final String plan;
  final int usedRecordings;
  final int totalLimit;

  const RecordPage({
    super.key,
    required this.isRecording,
    required this.timerText,
    required this.onToggle,
    required this.plan,
    required this.usedRecordings,
    required this.totalLimit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isUnlimited = totalLimit > 1000;
    final progress = isUnlimited ? 1.0 : (usedRecordings / totalLimit).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Plan Usage Indicator - NOW AT THE VERY TOP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Plan ${plan.substring(0, 1).toUpperCase()}${plan.substring(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Text(
                      isUnlimited ? "\u221E" : '$usedRecordings / $totalLimit',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: isDarkMode ? Colors.white10 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.9 ? Colors.redAccent : const Color(0xFF6D28D9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Titles
          Column(
            children: [
              Text(
                l10n.translate('captureIdeas'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.translate('aiWillHandle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color ??
                      Colors.blueGrey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Spacer(flex: 3), // This pushes the mic up
          // Mic Button
          Stack(
            alignment: Alignment.center,
            children: [
              if (isRecording) ...[
                const _AnimatedWave(
                  size: 200,
                  opacity: 0.28,
                  duration: Duration(milliseconds: 1300),
                ),
                const _AnimatedWave(
                  size: 160,
                  opacity: 0.24,
                  duration: Duration(milliseconds: 1100),
                ),
                const _AnimatedWave(
                  size: 120,
                  opacity: 0.2,
                  duration: Duration(milliseconds: 900),
                ),
              ],
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 140,
                  height: 140,
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
                                : AppColors.primary)
                            .withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    isRecording ? Icons.multitrack_audio : Icons.mic_none,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(flex: 2), // Space between mic and timer
          // Timer
          Column(
            children: [
              Text(
                timerText,
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w200,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isRecording
                    ? l10n.translate('recordingNow')
                    : l10n.translate('tapCenterToStart'),
                style: TextStyle(
                  color: isRecording ? Colors.redAccent : Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(flex: 5), // Deep push from bottom to raise everything
        ],
      ),
    );
  }
}

class _AnimatedWave extends StatefulWidget {
  final double size;
  final double opacity;
  final Duration duration;

  const _AnimatedWave({
    required this.size,
    required this.opacity,
    required this.duration,
  });

  @override
  State<_AnimatedWave> createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<_AnimatedWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        final scale = 0.75 + (t * 0.55);
        final alpha = (1 - t) * widget.opacity;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(alpha),
            ),
          ),
        );
      },
    );
  }
}
