import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ReadingVerificationScreen extends StatefulWidget {
  final String studentName;
  final String materialTitle;
  final String audioPath;
  final Map<String, dynamic> accuracy;

  const ReadingVerificationScreen({
    super.key,
    required this.studentName,
    required this.materialTitle,
    required this.audioPath,
    required this.accuracy,
  });

  @override
  State<ReadingVerificationScreen> createState() =>
      _ReadingVerificationScreenState();
}

class _ReadingVerificationScreenState
    extends State<ReadingVerificationScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();

  final Map<int, bool> decisions = {};

  int? playingIndex;

  Duration position = Duration.zero;

  Duration? stopAtPosition;

  Duration? _currentStartPosition;

  Timer? _snippetTimer;

  bool _seekVerified = false;

  bool _sourceLoaded = false;

  @override
  void initState() {
    super.initState();

    audioPlayer.onPositionChanged.listen((newPosition) {
      if (!mounted) return;

      if (_currentStartPosition != null) {
        if ((newPosition - _currentStartPosition!).abs() <
                const Duration(milliseconds: 1500) ||
            (newPosition >= _currentStartPosition! &&
                (stopAtPosition == null || newPosition <= stopAtPosition!))) {
          _seekVerified = true;
        }
      }

      if (_seekVerified &&
          stopAtPosition != null &&
          newPosition >= stopAtPosition!) {
        stopSection();
        return;
      }

      setState(() {
        position = newPosition;
      });
    });

    audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;

      _snippetTimer?.cancel();
      _snippetTimer = null;
      setState(() {
        playingIndex = null;
        position = Duration.zero;
        stopAtPosition = null;
        _seekVerified = false;
        _currentStartPosition = null;
      });
    });
  }

  @override
  void dispose() {
    _snippetTimer?.cancel();
    audioPlayer.stop();
    audioPlayer.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get mismatches {
    final data =
        (widget.accuracy['mismatch_words'] as List?) ?? [];

    return data
        .map(
          (item) => Map<String, dynamic>.from(
            item as Map,
          ),
        )
        .toList();
  }

  List<Map<String, dynamic>> get missingWords {
    final data =
        (widget.accuracy['missing_words'] as List?) ?? [];

    return data.map((item) {
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }

      return {
        'word': item.toString(),
      };
    }).toList();
  }

  List<Map<String, dynamic>> get extraWords {
    final data =
        (widget.accuracy['extra_words'] as List?) ?? [];

    return data.map((item) {
      if (item is Map) {
        return Map<String, dynamic>.from(item);
      }

      return {
        'word': item.toString(),
      };
    }).toList();
  }

  int get totalErrors {
    return mismatches.length +
        missingWords.length +
        extraWords.length;
  }

  bool get allReviewed {
    return decisions.length == totalErrors;
  }

  void markAllStudentCorrect() {
    setState(() {
      int idx = 0;
      for (int i = 0; i < mismatches.length; i++) {
        decisions[idx++] = true;
      }
      for (int i = 0; i < missingWords.length; i++) {
        decisions[idx++] = false;
      }
      for (int i = 0; i < extraWords.length; i++) {
        decisions[idx++] = false;
      }
    });
  }

  void keepAllDetectedErrors() {
    setState(() {
      int idx = 0;
      for (int i = 0; i < mismatches.length; i++) {
        decisions[idx++] = false;
      }
      for (int i = 0; i < missingWords.length; i++) {
        decisions[idx++] = true;
      }
      for (int i = 0; i < extraWords.length; i++) {
        decisions[idx++] = true;
      }
    });
  }

  Future<void> playSection(
    int index,
    Map<String, dynamic> error,
  ) async {
    final start =
        (error['start'] as num?)?.toDouble();

    final end =
        (error['end'] as num?)?.toDouble();

    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Audio timing is not available for this error.',
          ),
        ),
      );

      return;
    }

    if (widget.audioPath.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio recording is not available for playback.'),
        ),
      );
      return;
    }

    _snippetTimer?.cancel();
    _snippetTimer = null;
    _seekVerified = false;
    stopAtPosition = null;

    final startSeconds =
        (start - 0.8).clamp(
      0.0,
      double.infinity,
    );

    final endSeconds = end + 0.8;

    final startPosition = Duration(
      milliseconds:
          (startSeconds * 1000).round(),
    );

    final endPosition = Duration(
      milliseconds:
          (endSeconds * 1000).round(),
    );

    final snippetDuration = endPosition - startPosition;

    _currentStartPosition = startPosition;

    setState(() {
      playingIndex = index;
      position = startPosition;
    });

    try {
      final source = kIsWeb
          ? UrlSource(widget.audioPath)
          : DeviceFileSource(widget.audioPath);

      if (!_sourceLoaded) {
        await audioPlayer.play(
          source,
          position: startPosition,
        );
        _sourceLoaded = true;
      } else {
        try {
          await audioPlayer.pause();
          await audioPlayer.seek(startPosition);
          await audioPlayer.resume();
        } catch (_) {
          await audioPlayer.play(
            source,
            position: startPosition,
          );
        }
      }

      stopAtPosition = endPosition;

      _snippetTimer = Timer(
        snippetDuration + const Duration(milliseconds: 300),
        () {
          if (mounted && playingIndex == index) {
            stopSection();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        _snippetTimer?.cancel();
        _snippetTimer = null;
        setState(() {
          playingIndex = null;
          stopAtPosition = null;
          _seekVerified = false;
          _currentStartPosition = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not play audio snippet. You can still review and verify errors below.',
            ),
          ),
        );
      }
    }
  }

  Future<void> stopSection() async {
    _snippetTimer?.cancel();
    _snippetTimer = null;
    stopAtPosition = null;
    _seekVerified = false;
    _currentStartPosition = null;

    try {
      await audioPlayer.pause();
    } catch (_) {}

    if (mounted) {
      setState(() {
        playingIndex = null;
      });
    }
  }

  void confirmReview() {
    if (!allReviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please review all $totalErrors items (${decisions.length}/$totalErrors selected), or use the quick buttons above.',
          ),
        ),
      );

      return;
    }

    Navigator.pop(context, decisions);
  }

  String formatTimestamp(double seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toStringAsFixed(1).padLeft(4, '0')}';
  }

  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFFAF9F5);

  @override
  Widget build(BuildContext context) {
    int index = 0;

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
        title: const Text(
          'Reading Verification',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.verified_user_rounded,
                              color: textPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.studentName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Passage: ${widget.materialTitle} • ${totalErrors == 1 ? "1 possible error" : "$totalErrors possible errors"} (${decisions.length}/$totalErrors reviewed)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: markAllStudentCorrect,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Mark All Read Correctly'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF047857),
                        side: const BorderSide(color: Color(0xFFA7F3D0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: keepAllDetectedErrors,
                      icon: const Icon(Icons.error_outline, size: 16),
                      label: const Text('Keep All as Errors'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      if (mismatches.isNotEmpty)
                        ...mismatches.map((item) {
                          final currentIndex = index++;
                          return _buildMismatchCard(currentIndex, item);
                        }),
                      if (missingWords.isNotEmpty)
                        ...missingWords.map((item) {
                          final currentIndex = index++;
                          return _buildMissingWordCard(currentIndex, item);
                        }),
                      if (extraWords.isNotEmpty)
                        ...extraWords.map((item) {
                          final currentIndex = index++;
                          return _buildExtraWordCard(currentIndex, item);
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: confirmReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'CONFIRM REVIEW',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMismatchCard(
    int index,
    Map<String, dynamic> item,
  ) {
    final expected =
        item['expected'].toString();

    final detected =
        item['student'].toString();

    final start =
        (item['start'] as num?)?.toDouble();

    final end =
        (item['end'] as num?)?.toDouble();

    final timestampType =
        item['timestamp_type']?.toString();

    return Card(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Possible misread word',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Expected in passage: "$expected"',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            Text(
              'Heard by system: "$detected"',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            if (start != null && end != null)
              Text(
                timestampType == 'surrounding'
                    ? 'Around: '
                        '${formatTimestamp(start)} – '
                        '${formatTimestamp(end)}'
                    : 'Time: '
                        '${formatTimestamp(start)} – '
                        '${formatTimestamp(end)}',
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),

            const SizedBox(height: 12),

            if (start != null && end != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      playingIndex == index
                          ? stopSection
                          : () => playSection(
                                index,
                                item,
                              ),
                  icon: Icon(
                    playingIndex == index
                        ? Icons.stop
                        : Icons.play_arrow,
                  ),
                  label: Text(
                    playingIndex == index
                        ? 'STOP SECTION'
                        : 'PLAY THIS SECTION',
                  ),
                ),
              ),

            const SizedBox(height: 10),

            RadioGroup<bool>(
              groupValue:
                  decisions[index],
              onChanged: (value) {
                setState(() {
                  decisions[index] = value!;
                });
              },
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: true,
                    title: Text(
                      'Student read "$expected" correctly',
                    ),
                  ),
                  RadioListTile<bool>(
                    value: false,
                    title: Text(
                      'Student actually said the word "$detected"',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingWordCard(
    int index,
    Map<String, dynamic> item,
  ) {
    final word = item['word'].toString();
    final start = (item['start'] as num?)?.toDouble();
    final end = (item['end'] as num?)?.toDouble();
    final timestampType = item['timestamp_type']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Possible skipped word',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Passage word: "$word"',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (start != null && end != null)
              Text(
                timestampType == 'surrounding'
                    ? 'Around: ${formatTimestamp(start)} – ${formatTimestamp(end)}'
                    : 'Time: ${formatTimestamp(start)} – ${formatTimestamp(end)}',
                style: const TextStyle(fontSize: 15),
              ),
            const SizedBox(height: 12),
            if (start != null && end != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: playingIndex == index
                      ? stopSection
                      : () => playSection(index, item),
                  icon: Icon(
                    playingIndex == index ? Icons.stop : Icons.play_arrow,
                  ),
                  label: Text(
                    playingIndex == index
                        ? 'STOP SECTION'
                        : 'PLAY THIS SECTION',
                  ),
                ),
              ),
            const SizedBox(height: 10),
            RadioGroup<bool>(
              groupValue: decisions[index],
              onChanged: (value) {
                setState(() {
                  decisions[index] = value!;
                });
              },
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: false,
                    title: Text('Student actually said "$word"'),
                  ),
                  RadioListTile<bool>(
                    value: true,
                    title: Text('Count "$word" as skipped/missing'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraWordCard(
    int index,
    Map<String, dynamic> item,
  ) {
    final word = item['word'].toString();
    final start = (item['start'] as num?)?.toDouble();
    final end = (item['end'] as num?)?.toDouble();
    final timestampType = item['timestamp_type']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Possible extra word spoken',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Heard by system: "$word"',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (start != null && end != null)
              Text(
                timestampType == 'surrounding'
                    ? 'Around: ${formatTimestamp(start)} – ${formatTimestamp(end)}'
                    : 'Time: ${formatTimestamp(start)} – ${formatTimestamp(end)}',
                style: const TextStyle(fontSize: 15),
              ),
            const SizedBox(height: 12),
            if (start != null && end != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: playingIndex == index
                      ? stopSection
                      : () => playSection(index, item),
                  icon: Icon(
                    playingIndex == index ? Icons.stop : Icons.play_arrow,
                  ),
                  label: Text(
                    playingIndex == index
                        ? 'STOP SECTION'
                        : 'PLAY THIS SECTION',
                  ),
                ),
              ),
            const SizedBox(height: 10),
            RadioGroup<bool>(
              groupValue: decisions[index],
              onChanged: (value) {
                setState(() {
                  decisions[index] = value!;
                });
              },
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: false,
                    title: Text('Ignore "$word" (noise or part of passage)'),
                  ),
                  RadioListTile<bool>(
                    value: true,
                    title: Text('Count "$word" as an inserted extra word'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
