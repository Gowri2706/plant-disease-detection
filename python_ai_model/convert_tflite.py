"""
=========================================================================
STEP: CONVERT TRAINED MODEL TO TFLITE (for the Flutter app)
=========================================================================
Converts model/plant_disease_model.h5 -> model/plant_disease_model.tflite
Also writes model/labels.txt (one class name per line, in the correct
index order) which the Flutter app reads at inference time.

RUN (after train.py has finished and plant_disease_model.h5 exists):
    python convert_tflite.py
=========================================================================
"""

import os
import json
import tensorflow as tf

BASE_DIR = os.path.dirname(__file__)
MODEL_DIR = os.path.join(BASE_DIR, "model")

H5_PATH = os.path.join(MODEL_DIR, "plant_disease_model.h5")
TFLITE_PATH = os.path.join(MODEL_DIR, "plant_disease_model.tflite")
LABELS_PATH = os.path.join(MODEL_DIR, "labels.txt")
CLASS_INDEX_PATH = os.path.join(MODEL_DIR, "class_indices.json")

if not os.path.exists(H5_PATH):
    raise SystemExit(f"Could not find {H5_PATH}. Run train.py first.")

print("Loading trained model...")
model = tf.keras.models.load_model(H5_PATH)

print("Converting to TensorFlow Lite (with optimization for mobile)...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

with open(TFLITE_PATH, "wb") as f:
    f.write(tflite_model)
print(f"Saved: {TFLITE_PATH}")

# Write labels.txt in the correct index order
with open(CLASS_INDEX_PATH) as f:
    idx_to_class = json.load(f)

with open(LABELS_PATH, "w") as f:
    for i in range(len(idx_to_class)):
        f.write(idx_to_class[str(i)] + "\n")
print(f"Saved: {LABELS_PATH}")

print("\nDONE. Copy these 2 files into flutter_app/assets/ :")
print(" -", TFLITE_PATH)
print(" -", LABELS_PATH)
