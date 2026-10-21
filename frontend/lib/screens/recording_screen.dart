import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import '../models/reading_material.dart';
import 'recording_review_screen.dart';

class RecordingScreen extends StatefulWidget {
  final int? studentId;
  final String studentName;
  final int? materialId;
  final String materialTitle;
  final String passage;
  final List<ComprehensionQuestionItem> questions;

  const RecordingScreen({
    super.key,
    this.studentId,
    required this.studentName,
    this.materialId,
    required this.materialTitle,
    required this.passage,
    this.questions = const [],
  });

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with WidgetsBindingObserver {
  final AudioRecorder recorder = AudioRecorder();
  bool isRecording = false;
  bool _isBusy = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _lastTempFilePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    recorder.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached) &&
        isRecording) {
      stopRecording(navigateToReview: true);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatElapsed(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showPermissionDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'READ-EE needs microphone access to record your oral reading.\n\n'
          'If you previously denied permission, please enable it in:\n'
          'Android Settings → Apps → READ-EE → Permissions → Microphone → Allow.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> startRecording() async {
    if (_isBusy || isRecording) return;

    setState(() {
      _isBusy = true;
    });

    try {
      final hasPermission = await recorder.hasPermission();

      if (!hasPermission) {
        if (!mounted) return;
        _showPermissionDeniedDialog();
        return;
      }

      if (!kIsWeb && _lastTempFilePath != null) {
        try {
          final oldFile = File(_lastTempFilePath!);
          if (oldFile.existsSync()) {
            oldFile.deleteSync();
          }
        } catch (_) {}
      }

      final recordingPath = kIsWeb
          ? 'reading_recording.wav'
          : '${Directory.systemTemp.path}/reading_recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: recordingPath,
      );

      if (!mounted) return;

      _startTimer();
      setState(() {
        isRecording = true;
        _lastTempFilePath = recordingPath;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> stopRecording({bool navigateToReview = true}) async {
    if (_isBusy || !isRecording) return;

    setState(() {
      _isBusy = true;
    });

    try {
      final path = await recorder.stop();
      _stopTimer();

      if (!mounted) return;

      setState(() {
        isRecording = false;
      });

      if (!navigateToReview || path == null) {
        return;
      }

      if (!kIsWeb) {
        final recordedFile = File(path);
        if (!recordedFile.existsSync() || recordedFile.lengthSync() <= 44) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Recording was empty or too short. Please try recording again.',
              ),
            ),
          );
          return;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecordingReviewScreen(
            studentId: widget.studentId,
            studentName: widget.studentName,
            materialId: widget.materialId,
            materialTitle: widget.materialTitle,
            passage: widget.passage,
            audioPath: path,
            questions: widget.questions,
          ),
        ),
      );
    } catch (e) {
      _stopTimer();
      if (!mounted) return;
      setState(() {
        isRecording = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error stopping recording: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isRecording,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await stopRecording(navigateToReview: false);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
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
              const SizedBox(height: 20),
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
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(
                      isRecording ? Icons.mic : Icons.mic_none,
                      size: 56,
                      color: isRecording ? Colors.red : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isRecording
                          ? 'Recording: ${_formatElapsed(_elapsedSeconds)}'
                          : 'Tap START RECORDING when ready',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isRecording ? FontWeight.bold : FontWeight.normal,
                        color: isRecording ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isBusy
                      ? null
                      : (isRecording ? () => stopRecording() : startRecording),
                  icon: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                  ),
                  label: Text(
                    isRecording ? 'STOP RECORDING' : 'START RECORDING',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}