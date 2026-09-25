import 'package:flutter/material.dart';
import 'package:record/record.dart';

class RecordingScreen extends StatefulWidget {
  final String studentName;
  final String materialTitle;
  final String passage;

  const RecordingScreen({
    super.key,
    required this.studentName,
    required this.materialTitle,
    required this.passage,
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final AudioRecorder recorder = AudioRecorder();

  bool isRecording = false;

  @override
  void dispose() {
    recorder.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    final hasPermission = await recorder.hasPermission();

    if (!hasPermission) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required.'),
        ),
      );
      return;
    }

    await recorder.start(
      const RecordConfig(),
      path: 'reading_recording.wav',
    );

    setState(() {
      isRecording = true;
    });
  }

  Future<void> stopRecording() async {
    final path = await recorder.stop();

    setState(() {
      isRecording = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path == null
              ? 'Recording stopped.'
              : 'Recording saved.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Recording'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.studentName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.materialTitle,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Read the passage aloud.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.passage,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Icon(
                isRecording ? Icons.mic : Icons.mic_none,
                size: 60,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isRecording
                    ? stopRecording
                    : startRecording,
                icon: Icon(
                  isRecording ? Icons.stop : Icons.mic,
                ),
                label: Text(
                  isRecording
                      ? 'STOP RECORDING'
                      : 'START RECORDING',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}