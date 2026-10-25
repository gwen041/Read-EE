import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/class_section.dart';
import '../models/reading_material.dart';
import '../services/material_service.dart';
import 'recording_review_screen.dart';

class ReadingScreen extends StatefulWidget {
  final List<ClassSection>? classes;
  final ClassSection? initialClass;
  final StudentItem? initialStudent;

  const ReadingScreen({
    super.key,
    this.classes,
    this.initialClass,
    this.initialStudent,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFFF5BE41);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color backgroundColor = Color(0xFFFAF9F5);
  static const Color accentColor = Color(0xFFFEF3C7);

  AudioRecorder? _audioRecorder;
  AudioRecorder get _recorder => _audioRecorder ??= AudioRecorder();

  ClassSection? selectedClass;
  StudentItem? selectedStudent;
  ReadingMaterialItem? selectedMaterial;

  List<ReadingMaterialItem> _allMaterials = [];
  bool _isLoadingMaterials = true;

  bool isRecording = false;
  bool _isBusy = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _lastTempFilePath;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioRecorder = AudioRecorder();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    selectedClass = widget.initialClass ??
        (widget.classes != null && widget.classes!.isNotEmpty
            ? widget.classes!.first
            : null);
    selectedStudent = widget.initialStudent ??
        (selectedClass != null && selectedClass!.students.isNotEmpty
            ? selectedClass!.students.first
            : null);
    _loadMaterials();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulseController.dispose();
    _audioRecorder?.dispose();
    _audioRecorder = null;
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

  Future<void> _loadMaterials() async {
    try {
      final fetched = await MaterialService.getMaterials();
      if (!mounted) return;
      setState(() {
        _allMaterials = fetched;
        _isLoadingMaterials = false;
        final mats = filteredMaterials;
        if (selectedMaterial == null && mats.isNotEmpty) {
          selectedMaterial = mats.first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMaterials = false);
    }
  }

  int? _extractGradeNumber(String? gradeStr) {
    if (gradeStr == null) return null;
    final match = RegExp(r'\d+').firstMatch(gradeStr);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  List<ReadingMaterialItem> get filteredMaterials {
    if (selectedClass == null) return _allMaterials;
    final gradeNum = _extractGradeNumber(selectedClass!.gradeLevel);
    if (gradeNum == null) return _allMaterials;
    final matching =
        _allMaterials.where((m) => m.gradeLevel == gradeNum).toList();
    return matching.isNotEmpty ? matching : _allMaterials;
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.mic_off_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text(
              'Microphone Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'READ-EE needs microphone access to record oral reading.\n\n'
          'Please enable microphone access in your browser or device settings to continue.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: textPrimary,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> startRecording() async {
    if (_isBusy || isRecording) return;
    if (selectedMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reading material.')),
      );
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      bool hasPermission = false;
      try {
        hasPermission = await _recorder.hasPermission();
      } catch (permError) {
        debugPrint('Microphone permission check: $permError');

        if (kIsWeb) {
          hasPermission = true;
        }
      }

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

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: recordingPath,
      );

      if (!mounted) return;

      _startTimer();
      _pulseController.repeat(reverse: true);
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
      final path = await _recorder.stop();
      _stopTimer();
      _pulseController.stop();
      _pulseController.reset();

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

      final studentName = selectedStudent?.fullName ?? 'Student';
      final studentId = selectedStudent?.id;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecordingReviewScreen(
            studentId: studentId,
            studentName: studentName,
            materialId: selectedMaterial!.id,
            materialTitle: selectedMaterial!.title,
            passage: selectedMaterial!.passage,
            audioPath: path,
            questions: selectedMaterial!.questions,
          ),
        ),
      );
    } catch (e) {
      _stopTimer();
      _pulseController.stop();
      _pulseController.reset();
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

  Future<void> _cancelRecording() async {
    if (!isRecording) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Recording?'),
        content: const Text(
          'Are you sure you want to discard this oral recording? You can start again when ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Recording'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await stopRecording(navigateToReview: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording discarded.')),
        );
      }
    }
  }

  Widget _buildLiveTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _pulseAnimation,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatElapsed(_elapsedSeconds),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'REC',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscardButton() {
    return OutlinedButton.icon(
      onPressed: _isBusy ? null : _cancelRecording,
      icon: const Icon(
        Icons.close_rounded,
        size: 16,
        color: Color(0xFF64748B),
      ),
      label: const Text(
        'Discard',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildFinishButton({bool isFullWidth = false}) {
    return ElevatedButton.icon(
      onPressed: _isBusy
          ? null
          : () => stopRecording(navigateToReview: true),
      icon: const Icon(
        Icons.stop_rounded,
        size: 18,
        color: Colors.white,
      ),
      label: const Text(
        'FINISH & REVIEW',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: isFullWidth ? 16 : 18,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableMaterials = filteredMaterials;
    final studentName = selectedStudent?.fullName ?? 'Selected Student';
    final gradeLevel = selectedClass?.gradeLevel ?? 'Grade 4';
    final sectionName = selectedClass?.sectionName.startsWith('Section') == true
        ? selectedClass!.sectionName
        : 'Section ${selectedClass?.sectionName ?? "Class"}';

    return PopScope(
      canPop: !isRecording,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Discard Recording?'),
            content: const Text(
              'A recording is currently in progress. Leaving this screen will discard the recording.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Stay'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Discard & Leave'),
              ),
            ],
          ),
        );

        if (shouldLeave == true && context.mounted) {
          await stopRecording(navigateToReview: false);
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Oral Reading Assessment',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: _isLoadingMaterials
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Column(
                    children: [

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth >= 540;

                                    final studentInfo = Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: accentColor,
                                          child: Text(
                                            studentName.isNotEmpty
                                                ? studentName[0].toUpperCase()
                                                : 'S',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                studentName,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: gradeLevel
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: textPrimary,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: ' - $sectionName',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );

                                    final materialSelector = availableMaterials
                                            .isEmpty
                                        ? const Text(
                                            'No reading materials found',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFD97706),
                                            ),
                                          )
                                        : SizedBox(
                                            width:
                                                isWide ? 260 : double.infinity,
                                            height: 42,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFFE2E8F0),
                                                ),
                                              ),
                                              child:
                                                  DropdownButtonHideUnderline(
                                                child: DropdownButton<
                                                    ReadingMaterialItem>(
                                                  value: selectedMaterial,
                                                  isExpanded: true,
                                                  icon: const Icon(
                                                    Icons.arrow_drop_down,
                                                    color: textSecondary,
                                                  ),
                                                  hint: const Text(
                                                    'Select Material',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  items: availableMaterials
                                                      .map((mat) {
                                                    return DropdownMenuItem<
                                                        ReadingMaterialItem>(
                                                      value: mat,
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .menu_book_rounded,
                                                            size: 16,
                                                            color: Color(
                                                                0xFF10B981),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              mat.title,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    textPrimary,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onChanged: isRecording
                                                      ? null
                                                      : (val) {
                                                          if (val != null) {
                                                            setState(() =>
                                                                selectedMaterial =
                                                                    val);
                                                          }
                                                        },
                                                ),
                                              ),
                                            ),
                                          );

                                    if (isWide) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(child: studentInfo),
                                          const SizedBox(width: 16),
                                          materialSelector,
                                        ],
                                      );
                                    } else {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          studentInfo,
                                          const SizedBox(height: 12),
                                          materialSelector,
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),

                              if (selectedMaterial != null) ...[
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isRecording
                                          ? primaryColor.withValues(alpha: 0.8)
                                          : const Color(0xFFE2E8F0),
                                      width: isRecording ? 1.5 : 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [

                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: accentColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.article_outlined,
                                                color: textPrimary,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                selectedMaterial!.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${_countWords(selectedMaterial!.passage)} words • ${selectedMaterial!.questions.length} questions',
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
                                        padding: const EdgeInsets.fromLTRB(
                                          22,
                                          20,
                                          22,
                                          28,
                                        ),
                                        child: Text(
                                          selectedMaterial!.passage,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            height: 1.75,
                                            letterSpacing: 0.2,
                                            fontWeight: FontWeight.w400,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: const Border(
                            top: BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
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
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (!isRecording) {
                                  return Center(
                                    child: SizedBox(
                                      width: constraints.maxWidth > 300
                                          ? 280
                                          : double.infinity,
                                      height: 46,
                                      child: ElevatedButton.icon(
                                        onPressed: (selectedMaterial == null ||
                                                _isBusy)
                                            ? null
                                            : startRecording,
                                        icon: const Icon(Icons.mic_rounded,
                                            size: 20),
                                        label: const Text(
                                          'START RECORDING',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: textPrimary,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                if (constraints.maxWidth >= 480) {
                                  return Row(
                                    children: [
                                      _buildLiveTimer(),
                                      const Spacer(),
                                      _buildDiscardButton(),
                                      const SizedBox(width: 10),
                                      _buildFinishButton(),
                                    ],
                                  );
                                }

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildLiveTimer(),
                                        _buildDiscardButton(),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child:
                                          _buildFinishButton(isFullWidth: true),
                                    ),
                                  ],
                                );
                              },
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
}
