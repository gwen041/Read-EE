import '../models/assessment.dart';

class AssessmentStore {
  static final List<Assessment> assessments = [];

  static void addAssessment(Assessment assessment) {
    assessments.insert(0, assessment);
  }
}