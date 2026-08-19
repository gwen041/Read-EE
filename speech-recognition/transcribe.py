from faster_whisper import WhisperModel

model = WhisperModel (
  'small.en',
  device = 'cpu',
  compute_type = 'int8'
)

segments, info = model.transcribe(
  'audio/filoaccent.wav',
  beam_size=5,
  temperature=0,
  condition_on_previous_text=False,
  word_timestamps=True
)

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