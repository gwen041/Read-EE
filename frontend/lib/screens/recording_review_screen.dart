import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/reading_material.dart';
import 'quiz_screen.dart';

class RecordingReviewScreen extends StatefulWidget {
  final int? studentId;
  final String studentName;
  final int? materialId;
  final String materialTitle;
  final String passage;
  final String audioPath;
  final List<ComprehensionQuestionItem> questions;

  const RecordingReviewScreen({
    super.key,
    this.studentId,
    required this.studentName,
    this.materialId,
    required this.materialTitle,
    required this.passage,
    required this.audioPath,
    this.questions = const [],
  });

  @override
  State<RecordingReviewScreen> createState() => _RecordingReviewScreenState();
}

class _RecordingReviewScreenState extends State<RecordingReviewScreen> {
  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFFAF9F5);
  static const Color accentColor = Color(0xFFFEF3C7);

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
    try {
      await audioPlayer.play(
        kIsWeb
            ? UrlSource(widget.audioPath)
            : DeviceFileSource(widget.audioPath),
      );

      if (mounted) {
        setState(() {
          isPlaying = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not play recording: $e'),
        ),
      );
    }
  }

  Future<void> pauseRecordingPlayback() async {
    await audioPlayer.pause();
    if (mounted) {
      setState(() {
        isPlaying = false;
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

  Future<void> restartPlayback() async {
    await audioPlayer.seek(Duration.zero);
    if (!isPlaying) {
      await playRecording();
    }
  }

  String formatDuration(Duration dur) {
    final minutes = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int _countWords(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    return words.isEmpty || (words.length == 1 && words[0].isEmpty)
        ? 0
        : words.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () async {
            if (isPlaying) {
              await stopRecordingPlayback();
            }
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Review Recording',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: accentColor,
                                child: Text(
                                  widget.studentName.isNotEmpty
                                      ? widget.studentName[0].toUpperCase()
                                      : 'S',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.studentName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.menu_book_rounded,
                                          size: 14,
                                          color: textSecondary,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            widget.materialTitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isPlaying
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isPlaying
                                        ? const Color(0xFFA7F3D0)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPlaying
                                          ? Icons.graphic_eq_rounded
                                          : Icons.volume_up_rounded,
                                      size: 16,
                                      color: isPlaying
                                          ? const Color(0xFF059669)
                                          : textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isPlaying
                                          ? 'Playing Recording...'
                                          : 'Audio Ready for Review',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isPlaying
                                            ? const Color(0xFF047857)
                                            : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: primaryColor,
                                  inactiveTrackColor: const Color(0xFFE2E8F0),
                                  thumbColor: const Color(0xFF1E293B),
                                  overlayColor:
                                      primaryColor.withValues(alpha: 0.2),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7,
                                  ),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  min: 0,
                                  max: duration.inMilliseconds > 0
                                      ? duration.inMilliseconds.toDouble()
                                      : 1,
                                  value: position.inMilliseconds
                                      .clamp(
                                        0,
                                        duration.inMilliseconds > 0
                                            ? duration.inMilliseconds
                                            : 1,
                                      )
                                      .toDouble(),
                                  onChanged: duration == Duration.zero
                                      ? null
                                      : (value) async {
                                          final newPos = Duration(
                                            milliseconds: value.toInt(),
                                          );
                                          await audioPlayer.seek(newPos);
                                        },
                                ),
                              ),

                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formatDuration(position),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatDuration(duration),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [

                                  IconButton(
                                    tooltip: 'Restart from beginning',
                                    onPressed: restartPlayback,
                                    icon: const Icon(
                                      Icons.replay_rounded,
                                      size: 26,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  GestureDetector(
                                    onTap: isPlaying
                                        ? pauseRecordingPlayback
                                        : playRecording,
                                    child: Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1E293B)
                                                .withValues(alpha: 0.25),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 32,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  IconButton(
                                    tooltip: 'Stop',
                                    onPressed: stopRecordingPlayback,
                                    icon: const Icon(
                                      Icons.stop_rounded,
                                      size: 28,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (widget.passage.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.description_outlined,
                                        size: 16,
                                        color: textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'READING PASSAGE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: textSecondary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${_countWords(widget.passage)} words',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Color(0xFFE2E8F0),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Text(
                                    widget.passage,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      height: 1.65,
                                      color: textPrimary,
                                      letterSpacing: 0.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (isPlaying) {
                                  await stopRecordingPlayback();
                                }
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizScreen(
                                      studentId: widget.studentId,
                                      studentName: widget.studentName,
                                      materialId: widget.materialId,
                                      materialTitle: widget.materialTitle,
                                      passage: widget.passage,
                                      audioPath: widget.audioPath,
                                      questions: widget.questions,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                              label: const Text(
                                'CONTINUE TO COMPREHENSION QUIZ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: textPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                if (isPlaying) {
                                  await stopRecordingPlayback();
                                }
                                if (!context.mounted) return;
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: textSecondary,
                              ),
                              label: const Text(
                                'Record Again',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
