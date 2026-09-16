import joblib
import pandas as pd

model = joblib.load("ml/decision_tree_model.pkl")

def predict_classification(accuracy, wpm, comprehension):

  features = pd.DataFrame([{
    "accuracy": accuracy,
    "wpm": wpm,
    "comprehension": comprehension
  }])

  prediction = model.predict(features)[0]

  return prediction