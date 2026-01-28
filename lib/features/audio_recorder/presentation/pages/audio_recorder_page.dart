import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mind_voice/features/audio_recorder/presentation/providers/audio_recorder_provider.dart';
import 'package:mind_voice/features/audio_recorder/presentation/widgets/recorder_control.dart';
import 'package:mind_voice/features/audio_recorder/presentation/widgets/recording_tile.dart';

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
      context.read<AudioRecorderProvider>().loadRecordings();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                onDelete: () => provider.deleteRecording(recording.id),
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
            onStop: provider.stopRecording,
          );
        },
      ),
    );
  }
}
