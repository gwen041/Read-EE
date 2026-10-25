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

def get_profile_explanation(word_level, comprehension_level, reading_profile):
  if reading_profile == "Independent":
    return (
      "The student can read and understand this passage easily and "
      "confidently on their own, without needing assistance."
    )
  elif reading_profile == "Instructional":
    return (
      "The student is making good progress. They can read and understand "
      "this passage well with a little guidance and support from the teacher."
    )
  else:
    if word_level == "Frustration" and comprehension_level == "Frustration":
      return (
        "This passage is currently too challenging for the student in both "
        "word reading and understanding. Practicing with simpler stories will help them build confidence."
      )
    elif word_level == "Frustration":
      return (
        "The student understands the story, but had difficulty reading several words in this passage. "
        "They will benefit from practicing word recognition and sounds with easier materials."
      )
    else:
      return (
        "The student was able to read the words, but found it difficult to understand the passage. "
        "They will benefit from guided questions and vocabulary support."
      )

def calculate_reading_profile(word_reading_score, comprehension_score):
  word_level = get_word_reading_level(word_reading_score)
  comprehension_level = get_comprehension_level(comprehension_score)
  reading_profile = get_reading_profile(word_level, comprehension_level)
  explanation = get_profile_explanation(
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
