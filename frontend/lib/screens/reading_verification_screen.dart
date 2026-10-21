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

  @override
  void initState() {
    super.initState();

    audioPlayer.onPositionChanged.listen((newPosition) {
      if (!mounted) return;

      if (stopAtPosition != null &&
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

      setState(() {
        playingIndex = null;
        position = Duration.zero;
        stopAtPosition = null;
      });
    });
  }

  @override
  void dispose() {
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

  /// Marks every flagged item as "Student read correctly / Ignore STT noise"
  void markAllStudentCorrect() {
    setState(() {
      int idx = 0;
      for (int i = 0; i < mismatches.length; i++) {
        decisions[idx++] = true; // true = student said expected word
      }
      for (int i = 0; i < missingWords.length; i++) {
        decisions[idx++] = false; // false = word was NOT missing
      }
      for (int i = 0; i < extraWords.length; i++) {
        decisions[idx++] = false; // false = ignore extra word / STT noise
      }
    });
  }

  /// Marks every flagged item as a confirmed reading error
  void keepAllDetectedErrors() {
    setState(() {
      int idx = 0;
      for (int i = 0; i < mismatches.length; i++) {
        decisions[idx++] = false; // false = keep mismatch error
      }
      for (int i = 0; i < missingWords.length; i++) {
        decisions[idx++] = true; // true = keep missing error
      }
      for (int i = 0; i < extraWords.length; i++) {
        decisions[idx++] = true; // true = keep extra word error
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

    await audioPlayer.stop();

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

    setState(() {
      playingIndex = index;
      position = startPosition;
      stopAtPosition = endPosition;
    });

    final source = kIsWeb
        ? UrlSource(widget.audioPath)
        : DeviceFileSource(widget.audioPath);

    await audioPlayer.play(
      source,
      position: startPosition,
    );
  }

  Future<void> stopSection() async {
    await audioPlayer.stop();

    if (mounted) {
      setState(() {
        playingIndex = null;
        stopAtPosition = null;
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

  @override
  Widget build(BuildContext context) {
    int index = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.studentName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              widget.materialTitle,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              totalErrors == 1
                  ? 'The system detected 1 possible reading error (${decisions.length}/1 reviewed).'
                  : 'The system detected $totalErrors possible reading errors (${decisions.length}/$totalErrors reviewed).',
              style: const TextStyle(
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: markAllStudentCorrect,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Mark All as Read Correctly'),
                ),
                OutlinedButton.icon(
                  onPressed: keepAllDetectedErrors,
                  icon: const Icon(Icons.error_outline, size: 18),
                  label: const Text('Keep All as Errors'),
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

                      return _buildMismatchCard(
                        currentIndex,
                        item,
                      );
                    }),

                  if (missingWords.isNotEmpty)
                    ...missingWords.map((item) {
                      final currentIndex = index++;

                      return _buildMissingWordCard(
                        currentIndex,
                        item,
                      );
                    }),

                  if (extraWords.isNotEmpty)
                    ...extraWords.map((item) {
                      final currentIndex = index++;

                      return _buildExtraWordCard(
                        currentIndex,
                        item,
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: confirmReview,
                child: const Text(
                  'CONFIRM REVIEW',
                ),
              ),
            ),
          ],
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