# Read-EE Decision Tree Model Testing

## 1. Dataset

The Decision Tree model was trained using a synthetic development dataset
containing 80 records.

The dataset contains four classification labels:

- Normal: 20 records
- Decoding: 20 records
- Fluency: 20 records
- Comprehension: 20 records

The features used by the model are:

- Accuracy
- Words Per Minute (WPM)
- Comprehension Score

The dataset was created for development and testing purposes and does not
represent actual student assessment data.


## 2. Training and Testing

The dataset was divided into:

- Training samples: 64
- Testing samples: 16

The Decision Tree achieved:

- Test Accuracy: 100%

### Classification Report

| Class         | Precision | Recall | F1-Score | Support |

| Comprehension | 1.00 | 1.00 | 1.00 | 4 |
| Decoding      | 1.00 | 1.00 | 1.00 | 4 |
| Fluency       | 1.00 | 1.00 | 1.00 | 4 |
| Normal        | 1.00 | 1.00 | 1.00 | 4 |

### Confusion Matrix

| | Comprehension | Decoding | Fluency | Normal |

| Comprehension   | 4 | 0 | 0 | 0 |
| Decoding        | 0 | 4 | 0 | 0 |
| Fluency         | 0 | 0 | 4 | 0 |
| Normal          | 0 | 0 | 0 | 4 |



## 3. Controlled Prediction Testing

Additional test cases were created to check whether the trained model
produces reasonable classifications for different combinations of
accuracy, WPM, and comprehension.

| Student   | Accuracy | WPM | Comprehension | Predicted Class |

| Student 1 |    85    | 130 |      90       |     Decoding    |
| Student 2 |    95    | 90  |      90       |     Fluency     |
| Student 3 |    95    | 130 |      60       |  Comprehension  |

The predictions matched the expected classification for each controlled
test case.


## 4. Actual Audio Testing

The trained model was also tested using recorded reading samples.

All recordings used the same comprehension assessment.

| Audio File        | Accuracy |  WPM   | Comprehension | Classification |
 
| normal.wav        | 96.30%   | 174.57 |      100%     |     Normal     |
| fast.wav          | 96.30%   | 206.11 |      100%     |     Normal     |
| filoaccent.wav    | 100.00%  | 153.12 |      100%     |     Normal     |
| mispronounced.wav | 92.86%   | 128.44 |      100%     |     Normal     |
| repeated.wav      | 96.30%   | 98.78  |      100%     |     Fluency    |
| skipped.wav       | 88.89%   | 133.33 |      100%     |     Decoding   |
| slow.wav          | 92.59%   | 114.87 |      100%     |     Fluency    |
 

## 5. Observations

The updated dataset produced more varied classifications than the previous
20-record dataset.

The previous model classified all actual audio recordings as Normal.
After expanding the dataset and introducing more variation between classes,
the model classified the slower reading samples as Fluency and the sample
with skipped words as Decoding.

The Filipino-accented English sample was classified as Normal when the
speech was clearly recognized by the speech-to-text component.


## 6. Limitations

The 80-record dataset is synthetic and was created for development and
testing. Therefore, the 100% test accuracy should not be interpreted as
100% real-world classification accuracy.

Further validation using appropriately labeled student assessment data is
needed to evaluate the model's performance on actual learners.

The actual audio tests are also limited because the current recordings are
test samples rather than a large collection of real student assessments.