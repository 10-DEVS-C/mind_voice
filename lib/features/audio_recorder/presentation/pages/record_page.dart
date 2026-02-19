import 'package:flutter/material.dart';

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
              GestureDetector(
                onTap: onToggle,
                child: Container(
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
