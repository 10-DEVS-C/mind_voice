import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mind_voice/features/audio_recorder/presentation/providers/audio_recorder_provider.dart';
import 'package:mind_voice/features/audio_recorder/presentation/widgets/recorder_control.dart';
import 'package:mind_voice/features/audio_recorder/presentation/widgets/recording_tile.dart';
import 'package:mind_voice/features/auth/presentation/providers/auth_provider.dart';

class AudioRecorderPage extends StatefulWidget {
  const AudioRecorderPage({super.key});

  @override
  State<AudioRecorderPage> createState() => _AudioRecorderPageState();
}

class _AudioRecorderPageState extends State<AudioRecorderPage> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<AudioRecorderProvider>().loadRecordings(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Mind Voice Recorder')),
      body: Consumer<AudioRecorderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('Error: ${provider.errorMessage}'));
          }

          if (provider.recordings.isEmpty) {
            return const Center(child: Text('No recordings yet.'));
          }

          return ListView.builder(
            itemCount: provider.recordings.length,
            itemBuilder: (context, index) {
              final recording = provider.recordings[index];
              return RecordingTile(
                recording: recording,
                onDelete: () {
                  if (userId != null) {
                    provider.deleteRecording(recording.id, userId);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Consumer<AudioRecorderProvider>(
        builder: (context, provider, child) {
          return RecorderControl(
            isRecording: provider.isRecording,
            onStart: provider.startRecording,
            onStop: () {
              if (userId != null) {
                provider.stopRecording(userId);
              }
            },
          );
        },
      ),
    );
  }
}
