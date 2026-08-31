import string

from transcribe import transcribe_audio

def normalize_words(text):
  return [
    word.strip(string.punctuation)
    for word in text.split()
  ]

def generate_explanation(missing, extra, mismatch):

  errors = []

  if missing > 0:
    errors.append(f"skipped {missing} word{'s' if missing != 1 else ''}")

  if mismatch > 0:
    errors.append(f"misread {mismatch} word{'s' if mismatch != 1 else ''}")

  if extra > 0:
    errors.append(f"added {extra} extra word{'s' if extra != 1 else ''}")

  if not errors:
    return "The student read all words correctly."

  if len(errors) == 1:
    return "The student " + errors[0] + "."

  return "The student " + ", ".join(errors[:-1]) + ", and " + errors[-1] + "."


def calculate_accuracy(expected, student):

  expected_words = normalize_words(expected)
  student_words = normalize_words(student)

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

  # Backtrack through the DP table
  alignment = []

  i = len(expected_words)
  j = len(student_words)

  while i > 0 or j > 0:

    # Correct word
    if (i > 0 and j > 0 and expected_words[i - 1] == student_words[j - 1]):
      alignment.append( (expected_words[i - 1], student_words[j - 1], "correct") )
        
      i -= 1
      j -= 1

    # Missing expected word
    elif (i > 0 and dp[i][j] == dp[i - 1][j] + 1):
      alignment.append( (expected_words[i - 1], None, "missing") )

      i -= 1

    # Extra student word
    elif (j > 0 and dp[i][j] == dp[i][j - 1] + 1):
      alignment.append( (None, student_words[j - 1], "extra") )

      j -= 1

    # Mismatch
    elif (i > 0  and j > 0 and dp[i][j] == dp[i - 1][j - 1] + 1):
      alignment.append( (expected_words[i - 1], student_words[j - 1], "mismatch") )

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

  for expected_word, student_word, result in alignment:

    if result == "correct":
      print(expected_word, "->", student_word, "✓")
      correct += 1

    elif result == "mismatch":
      print(expected_word, "->", student_word, "✗ mismatch")
      mismatch += 1
      mismatch_words.append({
        "expected": expected_word,
        "student": student_word
      })

    elif result == "missing":
        print(expected_word, "-> -- ✗ missing")
        missing += 1
        missing_words.append(expected_word)

    elif result == "extra":
        print("-- ->", student_word, "✗ extra")
        extra += 1
        extra_words.append(student_word)

  # Calculate word accuracy
  total_words = correct + missing + extra + mismatch

  if total_words > 0:
    accuracy = (correct / total_words) * 100
  else:
    accuracy = 0  

  explanation = generate_explanation(
    missing,
    extra,
    mismatch
  )
  # Store the results
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
      print(item["expected"], "->", item["student"])

  if extra_words:
    print("Extra words:", extra_words)

  return result

# Test
expected = "The little boy walked to the school early in the morning. He carried his books in a blue bag and greeted his teacher at the classroom door."
student = transcribe_audio('audio/repeated.wav')

result = calculate_accuracy(expected, student)
print("\nResult object:")
print(result)