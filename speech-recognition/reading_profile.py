def get_word_reading_level(word_reading_score):
  rounded_score = round(float(word_reading_score))

  if rounded_score >= 97:
    return "Independent"
  elif rounded_score >= 90:
    return "Instructional"
  else:
    return "Frustration"


def get_comprehension_level(comprehension_score):
  rounded_score = round(float(comprehension_score))

  if rounded_score >= 80:
    return "Independent"
  elif rounded_score >= 59:
    return "Instructional"
  else:
    return "Frustration"


def get_reading_profile(word_reading_level, comprehension_level):
  # Table 8: Student's Reading Profile Per Passage
  if (
    word_reading_level == "Independent"
    and comprehension_level == "Independent"
  ):
    return "Independent"

  if (
    word_reading_level == "Frustration"
    or comprehension_level == "Frustration"
  ):
    return "Frustration"

  return "Instructional"


def get_profile_explanation(
  word_reading_score,
  comprehension_score,
  word_level,
  comprehension_level,
  reading_profile
):
  if word_level == "Independent":
    word_reason = f"Word Reading is Independent ({word_reading_score}% is within 97%-100%)"
  elif word_level == "Instructional":
    word_reason = f"Word Reading is Instructional ({word_reading_score}% is within 90%-96%)"
  else:
    word_reason = f"Word Reading is Frustration ({word_reading_score}% is 89% or below)"

  if comprehension_level == "Independent":
    comp_reason = f"Comprehension is Independent ({comprehension_score}% is within 80%-100%)"
  elif comprehension_level == "Instructional":
    comp_reason = f"Comprehension is Instructional ({comprehension_score}% is within 59%-79%)"
  else:
    comp_reason = f"Comprehension is Frustration ({comprehension_score}% is 58% or below)"

  if reading_profile == "Independent":
    meaning = (
      "Because both areas are Independent, the learner can read and "
      "understand this passage on their own without teacher assistance."
    )
  elif reading_profile == "Instructional":
    meaning = (
      "Based on Phil-IRI guidelines, the learner is at the Instructional "
      "level and can read and learn from this passage with teacher support."
    )
  else:
    meaning = (
      "Based on Phil-IRI guidelines, when either area is at the Frustration "
      "level, the overall profile is Frustration. This passage is currently "
      "too difficult for the learner and requires reading intervention."
    )

  return f"{word_reason} and {comp_reason}. {meaning}"


def calculate_reading_profile(word_reading_score, comprehension_score):
  word_level = get_word_reading_level(word_reading_score)
  comprehension_level = get_comprehension_level(comprehension_score)
  reading_profile = get_reading_profile(word_level, comprehension_level)
  explanation = get_profile_explanation(
    word_reading_score,
    comprehension_score,
    word_level,
    comprehension_level,
    reading_profile
  )

  return {
    "word_reading_level": word_level,
    "comprehension_level": comprehension_level,
    "reading_profile": reading_profile,
    "explanation": explanation
  }


if __name__ == "__main__":
  sample = calculate_reading_profile(93.75, 57)

  print("Oral Reading Profile:")
  print(f"Word Reading Level: {sample['word_reading_level']}")
  print(f"Comprehension Level: {sample['comprehension_level']}")
  print(f"Reading Profile: {sample['reading_profile']}")
  print(f"Explanation: {sample['explanation']}")