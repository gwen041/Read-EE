from faster_whisper import WhisperModel

def transcribe_audio(audio_path):

  model = WhisperModel (
    'small.en',
    device = 'cpu',
    compute_type = 'int8'
  )

  segments, info = model.transcribe(
    audio_path,
    beam_size=5,
    temperature=0,
    condition_on_previous_text=False,
    word_timestamps=True
  )

  student_words = []

  print('Detected language:', info.language)
  print('Language probability:', info.language_probability)
  print()
  print('Transcript:')
  print()

  for segment in segments:
    print(f"[{segment.start:.2f}s - {segment.end:.2f}s] {segment.text}")

    if segment.words:
      for word in segment.words:
        print(
          f"    {word.start:.2f}s - {word.end:.2f}s : {word.word}"
        )

        student_words.append(word.word.strip())

  student_text = " ".join(student_words)

  return student_text

if __name__ == "__main__":

  student_text = transcribe_audio('audio/normal.wav')

  print()
  print("Student transcript:")
  print(student_text)