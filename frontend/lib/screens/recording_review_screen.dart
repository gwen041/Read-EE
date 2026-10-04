import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class RecordingReviewScreen extends StatefulWidget {
  final String studentName;
  final String materialTitle;
  final String passage;
  final String audioPath;

  const RecordingReviewScreen({
    super.key,
    required this.studentName,
    required this.materialTitle,
    required this.passage,
    required this.audioPath,
  });

  @override
  State<RecordingReviewScreen> createState() =>
      _RecordingReviewScreenState();
}

class _RecordingReviewScreenState
    extends State<RecordingReviewScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();

  bool isPlaying = false;

  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();

    audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          duration = newDuration;
        });
      }
    });

    audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          position = newPosition;
        });
      }
    });

    audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          isPlaying = false;
          position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playRecording() async {
    await audioPlayer.play(
      UrlSource(widget.audioPath),
    );

    if (mounted) {
      setState(() {
        isPlaying = true;
      });
    }
  }

  Future<void> stopRecordingPlayback() async {
    await audioPlayer.stop();

    if (mounted) {
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
    }
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    final seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Recording'),
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
              'Recording Complete',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Listen to the recording before continuing.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.audiotrack,
                    size: 50,
                  ),
                  const SizedBox(height: 15),

                  Text(
                    isPlaying
                        ? 'Playing recording...'
                        : 'Recording ready',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Slider(
                    min: 0,
                    max: duration.inMilliseconds > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1,
                    value: position.inMilliseconds
                        .clamp(
                          0,
                          duration.inMilliseconds,
                        )
                        .toDouble(),
                    onChanged: duration == Duration.zero
                        ? null
                        : (value) async {
                            final newPosition =
                                Duration(
                              milliseconds: value.toInt(),
                            );

                            await audioPlayer.seek(
                              newPosition,
                            );
                          },
                  ),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatDuration(position)),
                      Text(formatDuration(duration)),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isPlaying
                            ? null
                            : playRecording,
                        icon: const Icon(
                          Icons.play_arrow,
                        ),
                        label: const Text('PLAY'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: isPlaying
                            ? stopRecordingPlayback
                            : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('STOP'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        studentName: widget.studentName,
                        materialTitle: widget.materialTitle,
                        passage: widget.passage,
                        audioPath: widget.audioPath,
                      ),
                    ),
                  );
                },
                child: const Text('CONTINUE TO QUIZ'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('RECORD AGAIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}