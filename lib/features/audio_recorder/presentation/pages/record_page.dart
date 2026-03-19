import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                l10n.translate('captureIdeas'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.translate('aiWillHandle'),
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.blueGrey,
                  fontSize: 16,
                ),
              ),
            ],
          ),
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
                    ? l10n.translate('recordingNow')
                    : l10n.translate('tapCenterToStart'),
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
