import sys
import json
import io
import contextlib

from assessment import run_assessment

data = json.load(sys.stdin)

audio_file = data['audioFile']
expected_text = data['expectedText']
student_answers = data['studentAnswers']

output = io.StringIO()

with contextlib.redirect_stdout(output):

  result = run_assessment(
    audio_file,
    expected_text,
    student_answers
  )

print(output.getvalue(), file=sys.stderr, end="")
print(json.dumps(result))