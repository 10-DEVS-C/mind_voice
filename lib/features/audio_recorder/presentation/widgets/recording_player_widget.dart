import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class RecordingPlayerWidget extends StatefulWidget {
  final String audioPath;
  final Duration? totalDuration;

  const RecordingPlayerWidget({
    super.key,
    required this.audioPath,
    this.totalDuration,
  });

  @override
  State<RecordingPlayerWidget> createState() => _RecordingPlayerWidgetState();
}

class _RecordingPlayerWidgetState extends State<RecordingPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _duration = widget.totalDuration ?? Duration.zero;

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = _duration;
        });
      }
    });

    // Set source but don't play
    _setSource();
  }

  Future<void> _setSource() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      if (widget.audioPath.isEmpty) return;
      await _audioPlayer.setSource(DeviceFileSource(widget.audioPath));
      // Optionally update duration if known immediately?
      // No, let listener handle it.
    } catch (e) {
      debugPrint("Error setting audio source: $e");
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        return;
      }

      final hasDuration = _duration > Duration.zero;
      final isAtEnd = hasDuration && _position >= _duration;

      if (isAtEnd) {
        await _audioPlayer.seek(Duration.zero);
      }

      await _audioPlayer.resume();
    } catch (e) {
      debugPrint("Error toggling audio playback: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audioPath.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_outlined, color: Colors.blueGrey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Audio en la nube',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Este archivo no está en tu dispositivo local.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 40,
                  color: const Color(0xFF6D28D9),
                ),
                onPressed: _togglePlayPause,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    Slider(
                      value: _position.inMilliseconds.toDouble().clamp(
                        0.0,
                        _duration.inMilliseconds.toDouble() > 0
                            ? _duration.inMilliseconds.toDouble()
                            : 0.0,
                      ),
                      min: 0.0,
                      max: _duration.inMilliseconds.toDouble() > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 0.0,
                      onChanged: (value) async {
                        final position = Duration(milliseconds: value.toInt());
                        await _audioPlayer.seek(position);
                      },
                      activeColor: const Color(0xFF6D28D9),
                      inactiveColor: Colors.grey.withValues(alpha: 0.3),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
