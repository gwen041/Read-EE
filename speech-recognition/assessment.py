from transcribe import transcribe_audio
from wpm import calculate_wpm
from comprehension import calculate_comprehension
from quiz_data import questions
from ml.predict import predict_classification
from accuracy import (calculate_accuracy, apply_teacher_corrections)
from reading_profile import calculate_reading_profile


def run_assessment(
  audio_file,
  expected_text,
  student_answers,
  custom_questions=None
):

  student_text, word_timestamps = transcribe_audio(audio_file)

  accuracy_result = calculate_accuracy(
    expected_text,
    student_text,
    word_timestamps
  )

  wpm_result = calculate_wpm(word_timestamps)

  active_questions = custom_questions if custom_questions else questions

  comprehension_result = calculate_comprehension(
    active_questions,
    student_answers
  )

  prediction = predict_classification(
    accuracy_result["accuracy"],
    wpm_result["wpm"],
    comprehension_result["score"]
  )

  profile_result = calculate_reading_profile(
    accuracy_result["accuracy"],
    comprehension_result["score"]
  )

  return {
    "accuracy": accuracy_result,
    "wpm": wpm_result,
    "comprehension": comprehension_result,
    "classification": prediction,
    "reading_profile": profile_result
  }

def finalize_assessment(
  accuracy_result,
  wpm_result,
  comprehension_result,
  decisions
):

  corrected_accuracy = apply_teacher_corrections(
    accuracy_result,
    decisions
  )

  prediction = predict_classification(
    corrected_accuracy["accuracy"],
    wpm_result["wpm"],
    comprehension_result["score"]
  )

  profile_result = calculate_reading_profile(
    corrected_accuracy["accuracy"],
    comprehension_result["score"]
  )

  return {
    "accuracy": corrected_accuracy,
    "wpm": wpm_result,
    "comprehension": comprehension_result,
    "classification": prediction,
    "reading_profile": profile_result
  }


if __name__ == "__main__":

  expected_text = (
    "The little boy walked to the school early in the morning. "
    "He carried his books in a blue bag and greeted his teacher "
    "at the classroom door."
  )

  audio_file = "audio/slow.wav"

  student_answers = [
    "B",
    "B",
    "A",
    "A",
    "B"
  ]

  result = run_assessment(
    audio_file,
    expected_text,
    student_answers
  )

  print("\n======ASSESSMENT RESULT=======")

  print("\nAccuracy:")
  print(result["accuracy"])

  print("\nReading Speed:")
  print(result["wpm"])

  print("\nComprehension:")
  print(result["comprehension"])

  print("\nML Classification:")
  print(result["classification"])

  print("\nReading Profile:")
  print(result["reading_profile"])

  test_decisions = {
    "0": True,
    "1": False
  }

  final_result = finalize_assessment(
    result["accuracy"],
    result["wpm"],
    result["comprehension"],
    test_decisions
  )

  print("\n======FINAL RESULT=======")

  print("\nFinal Accuracy:")
  print(final_result["accuracy"])

  print("\nFinal Classification:")
  print(final_result["classification"])

  print("\nFinal Reading Profile:")
  print(final_result["reading_profile"])