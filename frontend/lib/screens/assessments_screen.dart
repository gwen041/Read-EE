import 'package:flutter/material.dart';

import '../models/assessment.dart';
import '../services/assessment_service.dart';

class AssessmentsScreen extends StatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  List<Assessment> _assessments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAssessments();
  }

  Future<void> _loadAssessments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetched = await AssessmentService.getAssessments();
      if (!mounted) return;
      setState(() {
        _assessments = fetched;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessments'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadAssessments,
                        child: const Text('RETRY'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assessment History',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_assessments.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'No completed assessments yet.',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: _assessments.length,
                            itemBuilder: (context, index) {
                              final assessment = _assessments[index];

                              return Card(
                                margin: const EdgeInsets.only(
                                  bottom: 16,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(
                                    16.0,
                                  ),
                                  title: Text(
                                    assessment.studentName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          assessment.materialTitle,
                                        ),
                                        const SizedBox(
                                          height: 4,
                                        ),
                                        Text(
                                          _formatDate(
                                            assessment.date,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          'Accuracy: '
                                          '${assessment.accuracy}%  |  '
                                          'WPM: '
                                          '${assessment.wpm.toStringAsFixed(2)}',
                                        ),
                                        const SizedBox(
                                          height: 4,
                                        ),
                                        Text(
                                          'Reading Profile: '
                                          '${assessment.readingProfile} '
                                          '(Word: ${assessment.wordReadingLevel}, '
                                          'Comp: ${assessment.comprehensionLevel})',
                                        ),
                                        const SizedBox(
                                          height: 4,
                                        ),
                                        Text(
                                          'Classification: '
                                          '${assessment.classification}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right,
                                  ),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AssessmentDetailsDialog(
                                          assessment: assessment,
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class AssessmentDetailsDialog extends StatelessWidget {
  final Assessment assessment;

  const AssessmentDetailsDialog({
    super.key,
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Assessment Details',
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                assessment.studentName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                assessment.materialTitle,
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Date: ${_formatDate(assessment.date)}',
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Assessment Results',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildResultRow(
                'Initial Automated Accuracy',
                '${assessment.initialAccuracy}%',
              ),
              _buildResultRow(
                'Final Accuracy',
                '${assessment.accuracy}%',
              ),
              _buildResultRow(
                'Words Per Minute',
                assessment.wpm.toStringAsFixed(2),
              ),
              _buildResultRow(
                'Comprehension',
                '${assessment.comprehension}%',
              ),
              _buildResultRow(
                'Word Reading Level',
                assessment.wordReadingLevel,
              ),
              _buildResultRow(
                'Comprehension Level',
                assessment.comprehensionLevel,
              ),
              _buildResultRow(
                'Reading Profile (Phil-IRI)',
                assessment.readingProfile.toUpperCase(),
              ),
              _buildResultRow(
                'Classification',
                assessment.classification.toUpperCase(),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assessment.readingProfileExplanation,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Verification Status',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    assessment.isVerified
                        ? Icons.verified
                        : Icons.pending,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    assessment.isVerified
                        ? 'Teacher verification completed'
                        : 'Teacher verification pending',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Reading Passage',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  assessment.passage,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('CLOSE'),
        ),
      ],
    );
  }

  Widget _buildResultRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}