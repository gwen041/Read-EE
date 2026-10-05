import sys
import json
import io
import contextlib

from assessment import (
  run_assessment,
  finalize_assessment
)


data = json.load(sys.stdin)

action = data.get("action", "assessment")


if action == "assessment":

  audio_file = data["audioFile"]
  expected_text = data["expectedText"]
  student_answers = data["studentAnswers"]

  output = io.StringIO()

  with contextlib.redirect_stdout(output):
    result = run_assessment(
      audio_file,
      expected_text,
      student_answers
    )

  print(
    output.getvalue(),
    file=sys.stderr,
    end=""
  )

  print(json.dumps(result))


elif action == "finalize":

  accuracy_result = data["accuracy"]
  wpm_result = data["wpm"]
  comprehension_result = data["comprehension"]
  decisions = data["decisions"]

  result = finalize_assessment(
    accuracy_result,
    wpm_result,
    comprehension_result,
    decisions
  )

  print(json.dumps(result))


else:

  print(
    json.dumps({
      "message": "Invalid action."
    })
  )