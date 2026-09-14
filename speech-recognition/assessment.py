from transcribe import transcribe_audio
from accuracy import calculate_accuracy
from wpm import calculate_wpm
from comprehension import calculate_comprehension
from quiz_data import questions
import pandas as pd
import joblib

model = joblib.load("ml/decision_tree_model.pkl")


def run_assessment(audio_file, expected_text, student_answers):

  student_text, word_timestamps = transcribe_audio(audio_file)

  accuracy_result = calculate_accuracy(
    expected_text,
    student_text
  )

  wpm_result = calculate_wpm(word_timestamps)

  comprehension_result = calculate_comprehension(
    questions,
    student_answers
  )

  features = pd.DataFrame([{
    "accuracy": accuracy_result["accuracy"],
    "wpm": wpm_result["wpm"],
    "comprehension": comprehension_result["score"]
  }])

  prediction = model.predict(features)[0]

  return {
    "accuracy": accuracy_result,
    "wpm": wpm_result,
    "comprehension": comprehension_result,
    "classification": prediction
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
