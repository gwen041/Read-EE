import 'package:audioplayers/audioplayers.dart';
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

    /*
     * Give the teacher more context:
     *
     * 1 second before the flagged word
     * +
     * the flagged word
     * +
     * 1 second after the flagged word
     */
    final startSeconds =
        (start - 1.0).clamp(
      0.0,
      double.infinity,
    );

    final endSeconds = end + 1.0;

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

    await audioPlayer.play(
      UrlSource(widget.audioPath),
    );

    await audioPlayer.seek(startPosition);
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
        const SnackBar(
          content: Text(
            'Please review all detected reading differences.',
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              widget.materialTitle,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Reading Verification',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              totalErrors == 1
                  ? 'The system detected 1 possible reading error.'
                  : 'The system detected $totalErrors '
                      'possible reading errors.',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 20),

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

                      return _buildSingleWordCard(
                        currentIndex,
                        'Missing word',
                        item,
                      );
                    }),

                  if (extraWords.isNotEmpty)
                    ...extraWords.map((item) {
                      final currentIndex = index++;

                      return _buildSingleWordCard(
                        currentIndex,
                        'Extra word',
                        item,
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
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
              'Possible reading difference',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              'Expected: $expected',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            Text(
              'Detected: $detected',
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
                  fontSize: 16,
                ),
              ),

            const SizedBox(height: 15),

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
                      'Student actually said "$expected"',
                    ),
                  ),
                  RadioListTile<bool>(
                    value: false,
                    title: Text(
                      'Student actually said "$detected"',
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

  Widget _buildSingleWordCard(
    int index,
    String type,
    Map<String, dynamic> item,
  ) {
    final word =
        item['word'].toString();

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
            Text(
              type,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              word,
              style: const TextStyle(
                fontSize: 18,
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
                  fontSize: 16,
                ),
              ),

            const SizedBox(height: 15),

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
                      'The word "$word" is missing',
                    ),
                  ),
                  RadioListTile<bool>(
                    value: false,
                    title: Text(
                      'The word "$word" is not missing',
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
}