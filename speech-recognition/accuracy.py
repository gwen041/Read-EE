import string
from difflib import SequenceMatcher

from transcribe import transcribe_audio


FILLER_WORDS = {"uh", "um", "er", "ah", "hmm", "uhm"}


def normalize_words(text):
  words = []
  for raw in text.split():
    cleaned = raw.strip(string.punctuation).lower()
    if cleaned:
      words.append(cleaned)
  return words


def word_similarity(w1, w2):
  if w1 == w2:
    return 1.0
  return SequenceMatcher(None, w1, w2).ratio()


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

  # Build student_words directly from word_timestamps when available
  # so every student word index is 100% synchronized with its audio timestamp.
  timestamp_words = []
  student_words = []

  if word_timestamps:
    for item in word_timestamps:
      raw_token = str(item.get("word", ""))
      # Split tokens like "E.O." only if needed, keeping the same timestamp
      sub_tokens = [
        t.strip(string.punctuation).lower()
        for t in raw_token.replace(".", " ").split()
      ]
      sub_tokens = [t for t in sub_tokens if t]

      if not sub_tokens:
        cleaned = raw_token.strip(string.punctuation).lower()
        if cleaned:
          sub_tokens = [cleaned]

      for token in sub_tokens:
        student_words.append(token)
        timestamp_words.append({
          "word": token,
          "start": float(item["start"]),
          "end": float(item["end"])
        })
  else:
    student_words = normalize_words(student)

  print("Expected:", expected_words)
  print("Student:", student_words)

  rows = len(expected_words) + 1
  cols = len(student_words) + 1

  # Create the DP table and pointer table for accurate backtracking
  dp = [[0.0] * cols for _ in range(rows)]
  ptr = [[""] * cols for _ in range(rows)]

  for i in range(1, rows):
    dp[i][0] = float(i)
    ptr[i][0] = "missing"

  for j in range(1, cols):
    dp[0][j] = float(j)
    ptr[0][j] = "extra"

  # Fill the DP table using similarity-aware tie-breaking so that:
  # 1. Similar words (e.g. 'jumped' vs 'jump') pair as 'mismatch' instead of 'extra'
  # 2. Spoken filler sounds ('uh', 'um') prefer 'extra' instead of stealing expected words
  for i in range(1, rows):
    exp_w = expected_words[i - 1]
    for j in range(1, cols):
      stu_w = student_words[j - 1]

      if exp_w == stu_w:
        dp[i][j] = dp[i - 1][j - 1]
        ptr[i][j] = "correct"
        continue

      sim = word_similarity(exp_w, stu_w)
      if stu_w in FILLER_WORDS and exp_w not in FILLER_WORDS:
        sub_cost = 1.15
      else:
        # Slightly favor pairing similar words (e.g. 'jumped' <-> 'jump')
        sub_cost = 1.0 - (0.25 * sim)

      deletion = dp[i - 1][j] + 1.0
      insertion = dp[i][j - 1] + (0.95 if stu_w in FILLER_WORDS else 1.0)
      substitution = dp[i - 1][j - 1] + sub_cost

      best = min(substitution, deletion, insertion)
      dp[i][j] = best

      if best == substitution:
        ptr[i][j] = "mismatch"
      elif best == deletion:
        ptr[i][j] = "missing"
      else:
        ptr[i][j] = "extra"

  print("Levenshtein distance:", round(dp[-1][-1]))

  alignment = []
  i = len(expected_words)
  j = len(student_words)

  while i > 0 or j > 0:
    op = ptr[i][j]

    if op == "correct":
      alignment.append((
        expected_words[i - 1],
        student_words[j - 1],
        "correct",
        i - 1,
        j - 1
      ))
      i -= 1
      j -= 1
    elif op == "mismatch":
      alignment.append((
        expected_words[i - 1],
        student_words[j - 1],
        "mismatch",
        i - 1,
        j - 1
      ))
      i -= 1
      j -= 1
    elif op == "missing":
      alignment.append((
        expected_words[i - 1],
        None,
        "missing",
        i - 1,
        None
      ))
      i -= 1
    else:
      alignment.append((
        None,
        student_words[j - 1],
        "extra",
        None,
        j - 1
      ))
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
        "[OK]"
      )

      correct += 1

    elif result == "mismatch":
      print(
        expected_word,
        "->",
        student_word,
        "[MISMATCH]"
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
        "[MISSING]"
      )

      missing += 1

      # Use the closest surrounding recognized word timestamp.
      prev_ts = None
      next_ts = None

      for prev_item in reversed(alignment):
        prev_exp_idx = prev_item[3]
        prev_stu_idx = prev_item[4]
        if (
          prev_exp_idx is not None
          and prev_exp_idx < expected_index
          and prev_stu_idx is not None
          and prev_stu_idx < len(timestamp_words)
        ):
          prev_ts = timestamp_words[prev_stu_idx]
          break

      for next_item in alignment:
        next_exp_idx = next_item[3]
        next_stu_idx = next_item[4]
        if (
          next_exp_idx is not None
          and next_exp_idx > expected_index
          and next_stu_idx is not None
          and next_stu_idx < len(timestamp_words)
        ):
          next_ts = timestamp_words[next_stu_idx]
          break

      missing_result = {
        "word": expected_word
      }

      if prev_ts and next_ts:
        missing_result["start"] = prev_ts["start"]
        missing_result["end"] = next_ts["end"]
        missing_result["timestamp_type"] = "surrounding"
      elif next_ts:
        missing_result["start"] = next_ts["start"]
        missing_result["end"] = next_ts["end"]
        missing_result["timestamp_type"] = "surrounding"
      elif prev_ts:
        missing_result["start"] = prev_ts["start"]
        missing_result["end"] = prev_ts["end"]
        missing_result["timestamp_type"] = "surrounding"

      missing_words.append(missing_result)

    elif result == "extra":
      print(
        "-- ->",
        student_word,
        "[EXTRA]"
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
      correct += 1
      mismatch -= 1
    else:
      corrected_mismatches.append(item)

    error_index += 1

  corrected_missing = []

  for item in missing_words:

    decision = decisions.get(str(error_index))

    if decision is True:
      corrected_missing.append(item)
    else:
      correct += 1
      missing -= 1

    error_index += 1

  corrected_extra = []

  for item in extra_words:

    decision = decisions.get(str(error_index))

    if decision is True:
      corrected_extra.append(item)
    else:
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