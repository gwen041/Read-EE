import string

from transcribe import transcribe_audio


def normalize_words(text):
  return [
    word.strip(string.punctuation).lower()
    for word in text.split()
  ]


def generate_explanation(missing, extra, mismatch):

  errors = []

  if missing > 0:
    errors.append(
      f"skipped {missing} word{'s' if missing != 1 else ''}"
    )

  if mismatch > 0:
    errors.append(
      f"misread {mismatch} word{'s' if mismatch != 1 else ''}"
    )

  if extra > 0:
    errors.append(
      f"added {extra} extra word{'s' if extra != 1 else ''}"
    )

  if not errors:
    return "The student read all words correctly."

  if len(errors) == 1:
    return "The student " + errors[0] + "."

  return (
    "The student "
    + ", ".join(errors[:-1])
    + ", and "
    + errors[-1]
    + "."
  )


def calculate_accuracy(expected, student, word_timestamps):

  expected_words = normalize_words(expected)
  student_words = normalize_words(student)

  # Normalize the Whisper words while keeping their timestamps.
  timestamp_words = []

  for item in word_timestamps:
    normalized_word = item["word"].strip(string.punctuation)

    timestamp_words.append({
      "word": normalized_word,
      "start": item["start"],
      "end": item["end"]
    })

  print("Expected:", expected_words)
  print("Student:", student_words)

  rows = len(expected_words) + 1
  cols = len(student_words) + 1

  # Create the Levenshtein distance table
  dp = [[0] * cols for _ in range(rows)]

  # Initialize first column
  for i in range(rows):
    dp[i][0] = i

  # Initialize first row
  for j in range(cols):
    dp[0][j] = j

  # Fill the DP table
  for i in range(1, rows):
    for j in range(1, cols):

      if expected_words[i - 1] == student_words[j - 1]:
        cost = 0
      else:
        cost = 1

      deletion = dp[i - 1][j] + 1
      insertion = dp[i][j - 1] + 1
      substitution = dp[i - 1][j - 1] + cost

      dp[i][j] = min(
        deletion,
        insertion,
        substitution
      )

  print("Levenshtein distance:", dp[-1][-1])

  # Backtrack through the DP table.
  #
  # Each tuple contains:
  # expected word
  # student word
  # result
  # expected index
  # student index
  alignment = []

  i = len(expected_words)
  j = len(student_words)

  while i > 0 or j > 0:

    # Correct word
    if (
      i > 0
      and j > 0
      and expected_words[i - 1] == student_words[j - 1]
    ):
      alignment.append(
        (
          expected_words[i - 1],
          student_words[j - 1],
          "correct",
          i - 1,
          j - 1
        )
      )

      i -= 1
      j -= 1

    # Missing expected word
    elif (
      i > 0
      and dp[i][j] == dp[i - 1][j] + 1
    ):
      alignment.append(
        (
          expected_words[i - 1],
          None,
          "missing",
          i - 1,
          None
        )
      )

      i -= 1

    # Extra student word
    elif (
      j > 0
      and dp[i][j] == dp[i][j - 1] + 1
    ):
      alignment.append(
        (
          None,
          student_words[j - 1],
          "extra",
          None,
          j - 1
        )
      )

      j -= 1

    # Mismatch
    elif (
      i > 0
      and j > 0
      and dp[i][j] == dp[i - 1][j - 1] + 1
    ):
      alignment.append(
        (
          expected_words[i - 1],
          student_words[j - 1],
          "mismatch",
          i - 1,
          j - 1
        )
      )

      i -= 1
      j -= 1

  alignment.reverse()

  print("\nAlignment:")

  correct = 0
  missing = 0
  extra = 0
  mismatch = 0

  missing_words = []
  extra_words = []
  mismatch_words = []

  for (
    expected_word,
    student_word,
    result,
    expected_index,
    student_index
  ) in alignment:

    if result == "correct":
      print(
        expected_word,
        "->",
        student_word,
        "✓"
      )

      correct += 1

    elif result == "mismatch":
      print(
        expected_word,
        "->",
        student_word,
        "✗ mismatch"
      )

      mismatch += 1

      timestamp = None

      if (
        student_index is not None
        and student_index < len(timestamp_words)
      ):
        timestamp = timestamp_words[student_index]

      mismatch_result = {
        "expected": expected_word,
        "student": student_word
      }

      if timestamp:
        mismatch_result["start"] = timestamp["start"]
        mismatch_result["end"] = timestamp["end"]
        mismatch_result["timestamp_type"] = "exact"

      mismatch_words.append(mismatch_result)

    elif result == "missing":
      print(
        expected_word,
        "-> -- ✗ missing"
      )

      missing += 1

      # A missing word has no Whisper timestamp because
      # Whisper did not recognize the word.
      #
      # Use the closest surrounding recognized word instead.
      surrounding_timestamp = None

      # Look for the next recognized student word.
      for next_item in alignment:
        next_expected_index = next_item[3]
        next_student_index = next_item[4]

        if (
          next_expected_index is not None
          and next_expected_index > expected_index
          and next_student_index is not None
        ):
          if next_student_index < len(timestamp_words):
            surrounding_timestamp = timestamp_words[next_student_index]

          break

      # If there is no next word, use the previous
      # recognized student word.
      if surrounding_timestamp is None:
        for previous_item in reversed(alignment):
          previous_expected_index = previous_item[3]
          previous_student_index = previous_item[4]

          if (
            previous_expected_index is not None
            and previous_expected_index < expected_index
            and previous_student_index is not None
          ):
            if previous_student_index < len(timestamp_words):
              surrounding_timestamp = timestamp_words[
                previous_student_index
              ]

            break

      missing_result = {
        "word": expected_word
      }

      if surrounding_timestamp:
        missing_result["start"] = surrounding_timestamp["start"]
        missing_result["end"] = surrounding_timestamp["end"]
        missing_result["timestamp_type"] = "surrounding"

      missing_words.append(missing_result)

    elif result == "extra":
      print(
        "-- ->",
        student_word,
        "✗ extra"
      )

      extra += 1

      timestamp = None

      if (
        student_index is not None
        and student_index < len(timestamp_words)
      ):
        timestamp = timestamp_words[student_index]

      extra_result = {
        "word": student_word
      }

      if timestamp:
        extra_result["start"] = timestamp["start"]
        extra_result["end"] = timestamp["end"]
        extra_result["timestamp_type"] = "exact"

      extra_words.append(extra_result)

  # Calculate word accuracy
  total_words = (
    correct
    + missing
    + extra
    + mismatch
  )

  if total_words > 0:
    accuracy = (correct / total_words) * 100
  else:
    accuracy = 0

  explanation = generate_explanation(
    missing,
    extra,
    mismatch
  )

  result = {
    "accuracy": round(accuracy, 2),
    "correct": correct,
    "mismatch": mismatch,
    "missing": missing,
    "extra": extra,
    "mismatch_words": mismatch_words,
    "missing_words": missing_words,
    "extra_words": extra_words,
    "explanation": explanation
  }

  print("\nResults:")
  print("Correct:", correct)
  print("Mismatch:", mismatch)
  print("Missing:", missing)
  print("Extra:", extra)
  print("Accuracy:", round(accuracy, 2), "%")
  print("Explanation:", explanation)

  print("\nErrors:")

  if missing_words:
    print("Missing words:", missing_words)

  if mismatch_words:
    print("Misread words:")

    for item in mismatch_words:
      print(
        item["expected"],
        "->",
        item["student"]
      )

  if extra_words:
    print("Extra words:", extra_words)

  return result

def apply_teacher_corrections(accuracy_result, decisions):
  """
  Apply the teacher's verification decisions to the
  original STT accuracy result.

  decisions:
    {
      "0": true/false,
      "1": true/false,
      ...
    }

  For mismatches:
    true  = student actually said expected word
            -> STT was wrong -> correct the mismatch

    false = student actually said detected word
            -> keep the mismatch

  For missing words:
    true  = word really was missing
            -> keep the missing error

    false = word was actually spoken
            -> STT was wrong -> remove the missing error

  For extra words:
    true  = extra word was really spoken
            -> keep the extra error

    false = extra word was not actually spoken
            -> STT was wrong -> remove the extra error
  """

  corrected = dict(accuracy_result)

  mismatch_words = accuracy_result["mismatch_words"]
  missing_words = accuracy_result["missing_words"]
  extra_words = accuracy_result["extra_words"]

  correct = accuracy_result["correct"]
  mismatch = accuracy_result["mismatch"]
  missing = accuracy_result["missing"]
  extra = accuracy_result["extra"]

  error_index = 0

  corrected_mismatches = []

  for item in mismatch_words:

    decision = decisions.get(str(error_index))

    if decision is True:
      # Teacher confirmed that the expected word
      # was actually spoken.
      correct += 1
      mismatch -= 1

    else:
      corrected_mismatches.append(item)

    error_index += 1

  corrected_missing = []

  for item in missing_words:

    decision = decisions.get(str(error_index))

    if decision is True:
      # Teacher confirmed that the word was really missing.
      corrected_missing.append(item)

    else:
      # Teacher confirmed that the word was actually spoken.
      correct += 1
      missing -= 1

    error_index += 1

  corrected_extra = []

  for item in extra_words:

    decision = decisions.get(str(error_index))

    if decision is True:
      # Teacher confirmed that the extra word was really spoken.
      corrected_extra.append(item)

    else:
      # Teacher confirmed that this was an STT error.
      correct += 1
      extra -= 1

    error_index += 1

  total_words = (
    correct
    + mismatch
    + missing
    + extra
  )

  if total_words > 0:
    accuracy = (correct / total_words) * 100
  else:
    accuracy = 0

  corrected["accuracy"] = round(accuracy, 2)
  corrected["correct"] = correct
  corrected["mismatch"] = mismatch
  corrected["missing"] = missing
  corrected["extra"] = extra

  corrected["mismatch_words"] = corrected_mismatches
  corrected["missing_words"] = corrected_missing
  corrected["extra_words"] = corrected_extra

  corrected["explanation"] = generate_explanation(
    missing,
    extra,
    mismatch
  )

  return corrected


if __name__ == "__main__":

  expected = (
    "The little boy walked to the school early in the morning. "
    "He carried his books in a blue bag and greeted his teacher "
    "at the classroom door."
  )

  student, word_timestamps = transcribe_audio(
    'audio/repeated.wav'
  )

  result = calculate_accuracy(
    expected,
    student,
    word_timestamps
  )

  print("\nResult object:")
  print(result)