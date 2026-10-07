"""
=========================================================================
STEP: TEST A SINGLE IMAGE (on your PC, before putting it in the app)
=========================================================================
Use this to sanity-check the trained model on any photo before trusting
the Flutter app. It also demonstrates the exact "not a plant" logic that
the Flutter app copies: if the model's top confidence is below a
threshold, we refuse to answer instead of guessing.

RUN:
    python predict.py path/to/your/image.jpg
=========================================================================
"""

import sys
import os
import json
import numpy as np
from tensorflow.keras.preprocessing import image
import tensorflow as tf

BASE_DIR = os.path.dirname(__file__)
MODEL_DIR = os.path.join(BASE_DIR, "model")
MODEL_PATH = os.path.join(MODEL_DIR, "plant_disease_model.h5")
CLASS_INDEX_PATH = os.path.join(MODEL_DIR, "class_indices.json")
DISEASE_INFO_PATH = os.path.join(BASE_DIR, "disease_info.json")

# Below this confidence, we say "This is not a plant / unclear image"
# instead of forcing a guess. Tune this after you see real results.
CONFIDENCE_THRESHOLD = 0.60


def load_everything():
    model = tf.keras.models.load_model(MODEL_PATH)
    with open(CLASS_INDEX_PATH) as f:
        idx_to_class = json.load(f)
    with open(DISEASE_INFO_PATH, encoding="utf-8") as f:
        disease_info = json.load(f)
    return model, idx_to_class, disease_info


def predict(img_path):
    model, idx_to_class, disease_info = load_everything()

    img = image.load_img(img_path, target_size=(224, 224))
    arr = image.img_to_array(img) / 255.0
    arr = np.expand_dims(arr, axis=0)

    preds = model.predict(arr, verbose=0)[0]
    top_idx = int(np.argmax(preds))
    confidence = float(preds[top_idx])
    class_name = idx_to_class[str(top_idx)]

    print(f"\nRaw top prediction: {class_name}  (confidence: {confidence*100:.2f}%)")

    if confidence < CONFIDENCE_THRESHOLD:
        print("\nRESULT: 'This is not a plant.' (or image too unclear)")
        print("Reason: model confidence is below the safety threshold "
              f"({CONFIDENCE_THRESHOLD*100:.0f}%). The Flutter app does the "
              "exact same check to avoid showing a wrong disease name.")
        return

    info = disease_info.get(class_name, {})
    print("\nRESULT:")
    print("  Class key:", class_name)
    print("  English name:", info.get("name_en", class_name))
    print("  Tamil name:", info.get("name_ta", "-"))
    print("  Description (EN):", info.get("description_en", "-"))
    print("  Description (TA):", info.get("description_ta", "-"))
    print("  Solution (EN):", info.get("solution_en", "-"))
    print("  Solution (TA):", info.get("solution_ta", "-"))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python predict.py path/to/image.jpg")
        sys.exit(1)
    predict(sys.argv[1])
