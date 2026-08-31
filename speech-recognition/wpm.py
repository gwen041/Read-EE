def calculate_wpm(word_timestamps):

  if not word_timestamps:
    return {
      "word_count": 0,
      "reading_time_seconds": 0,
      "wpm": 0
    }

  first_word_start = word_timestamps[0]['start']
  last_word_end = word_timestamps[-1]['end']

  reading_time_seconds = last_word_end - first_word_start
  reading_time_minutes = reading_time_seconds / 60

  word_count = len(word_timestamps)

  wpm = word_count / reading_time_minutes

  return {
    "word_count": word_count,
    "reading_time_seconds": reading_time_seconds,
    "wpm": wpm
  }

if __name__ == "__main__":

  from transcribe import transcribe_audio

  student_text, word_timestamps = transcribe_audio(
    'audio/fast.wav'
  )

  result = calculate_wpm(word_timestamps)

  print()
  print("Reading speed:")
  print(f"Word count: {result['word_count']}")
  print(f"Reading time: {result['reading_time_seconds']:.2f} seconds")
  print(f"WPM: {result['wpm']:.2f}")