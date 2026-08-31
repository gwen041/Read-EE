def calculate_comprehension(questions, student_answers):

  correct = 0

  for question, student_answer in zip(questions, student_answers):

    if student_answer.strip().lower() == question["answer"].strip().lower():
      correct += 1

  total = len(questions)

  if total == 0:
    score = 0
  else:
    score = (correct / total) * 100

  return {
    "correct": correct,
    "total": total,
    "score": score
  }


if __name__ == "__main__":

  questions = [
    {
      "question": "Where did the boy walk?",
      "choices": [
        "The park",
        "The school",
        "The store",
        "The library"
      ],
      "answer": "The school"
    },
    {
      "question": "What did the boy carry?",
      "choices": [
        "Toys",
        "Food",
        "Books",
        "Clothes"
      ],
      "answer": "Books"
    },
    {
      "question": "Whom did the boy greet?",
      "choices": [
        "His friend",
        "His teacher",
        "His brother",
        "His neighbor"
      ],
      "answer": "His teacher"
    }
  ]

  student_answers = [
    "The school",
    "Books",
    "His teacher"
  ]

  result = calculate_comprehension(
    questions,
    student_answers
  )

  print("Comprehension:")
  print(f"Correct: {result['correct']}")
  print(f"Total: {result['total']}")
  print(f"Score: {result['score']:.2f}%")