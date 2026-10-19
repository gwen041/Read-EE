from quiz_data import questions

def calculate_comprehension(questions, student_answers):

  correct = 0

  type_results = {
    "literal": {
      "correct": 0,
      "total": 0
    },
    "inferential": {
      "correct": 0,
      "total": 0
    },
    "critical": {
      "correct": 0,
      "total": 0
    }
  }

  if len(questions) != len(student_answers):
    raise ValueError(
      "Number of questions and student answers do not match."
    )

  for question, student_answer in zip(questions, student_answers):

    question_type = question.get("type", "literal")
    if question_type not in type_results:
      question_type = "literal"

    type_results[question_type]["total"] += 1

    expected_answer = (
      question.get("answer")
      or question.get("correctAnswer")
      or ""
    )

    if student_answer.strip().lower() == expected_answer.strip().lower():
      correct += 1
      type_results[question_type]["correct"] += 1

  total = len(questions)

  if total == 0:
    score = 0
  else:
    score = round((correct / total) * 100, 2)

  for question_type in type_results:

    type_total = type_results[question_type]["total"]
    type_correct = type_results[question_type]["correct"]

    if type_total == 0:
      type_score = 0
    else:
      type_score = (type_correct / type_total) * 100

    type_results[question_type]["score"] = round(type_score, 2)

  return {
    "correct": correct,
    "total": total,
    "score": score,
    "by_type": type_results
  }

if __name__ == "__main__":

  student_answers = [
    "B",
    "B",
    "A",
    "A",
    "B"
  ]

  result = calculate_comprehension(
    questions,
    student_answers
  )

  print("Comprehension:")
  print(f"Correct: {result['correct']}")
  print(f"Total: {result['total']}")
  print(f"Score: {result['score']:.2f}%")

  print("\nBy Type:")

  for question_type, data in result["by_type"].items():
    print(
      f"{question_type.capitalize()}: "
      f"{data['correct']}/{data['total']} "
      f"({data['score']:.2f}%)"
    )