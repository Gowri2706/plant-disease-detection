"""
=========================================================================
STEP: MODEL TRAINING
=========================================================================
Trains a plant disease classifier using MobileNetV2 transfer learning.
Two-stage training strategy for the best realistic accuracy:
  Stage 1: freeze MobileNetV2 base, train only the new classifier head
  Stage 2: unfreeze the top layers of the base and fine-tune with a
           very small learning rate

WHY MobileNetV2?
  - Small, fast, made for mobile devices (perfect for a Flutter/TFLite app)
  - Already knows general image features from ImageNet, so it needs far
    less data/time to learn plant diseases well ("transfer learning")

HONEST NOTE:
  No training script can promise 100% accuracy. This setup realistically
  reaches ~95-97% validation accuracy on the PlantVillage-based dataset
  used here. Real-world photos (different lighting, background, phone
  camera quality) will usually score a bit lower than the lab dataset -
  this is normal for every plant-disease app that exists, not a bug in
  this code.

RUN (after download_dataset.py has finished):
    python train.py
=========================================================================
"""

import os
import json
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.preprocessing.image import ImageDataGenerator

# ---------------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------------
BASE_DIR = os.path.dirname(__file__)
DATASET_ROOT = os.path.join(
    BASE_DIR, "dataset",
    "New Plant Diseases Dataset(Augmented)",
    "New Plant Diseases Dataset(Augmented)",
)
TRAIN_DIR = os.path.join(DATASET_ROOT, "train")
VALID_DIR = os.path.join(DATASET_ROOT, "valid")
MODEL_DIR = os.path.join(BASE_DIR, "model")
os.makedirs(MODEL_DIR, exist_ok=True)

IMG_SIZE = (224, 224)
BATCH_SIZE = 32
STAGE1_EPOCHS = 8
STAGE2_EPOCHS = 6

if not os.path.isdir(TRAIN_DIR):
    raise SystemExit(
        f"Train folder not found at: {TRAIN_DIR}\n"
        "Run download_dataset.py first, or check the dataset folder name."
    )

# ---------------------------------------------------------------------
# DATA GENERATORS (with augmentation to reduce overfitting)
# ---------------------------------------------------------------------
train_datagen = ImageDataGenerator(
    rescale=1.0 / 255,
    rotation_range=25,
    width_shift_range=0.15,
    height_shift_range=0.15,
    shear_range=0.1,
    zoom_range=0.15,
    horizontal_flip=True,
    brightness_range=[0.8, 1.2],
)
valid_datagen = ImageDataGenerator(rescale=1.0 / 255)

train_gen = train_datagen.flow_from_directory(
    TRAIN_DIR, target_size=IMG_SIZE, batch_size=BATCH_SIZE, class_mode="categorical"
)
valid_gen = valid_datagen.flow_from_directory(
    VALID_DIR, target_size=IMG_SIZE, batch_size=BATCH_SIZE, class_mode="categorical", shuffle=False
)

NUM_CLASSES = train_gen.num_classes
print(f"Detected {NUM_CLASSES} classes.")

# Save class index mapping -> needed by predict.py and the Flutter app
class_indices = train_gen.class_indices
idx_to_class = {v: k for k, v in class_indices.items()}
with open(os.path.join(MODEL_DIR, "class_indices.json"), "w") as f:
    json.dump(idx_to_class, f, indent=2)
print("Saved class_indices.json")

# ---------------------------------------------------------------------
# MODEL: MobileNetV2 base + custom classification head
# ---------------------------------------------------------------------
base_model = MobileNetV2(
    input_shape=(224, 224, 3), include_top=False, weights="imagenet"
)
base_model.trainable = False  # Stage 1: freeze base

inputs = layers.Input(shape=(224, 224, 3))
x = base_model(inputs, training=False)
x = layers.GlobalAveragePooling2D()(x)
x = layers.Dropout(0.3)(x)
x = layers.Dense(256, activation="relu")(x)
x = layers.Dropout(0.3)(x)
outputs = layers.Dense(NUM_CLASSES, activation="softmax")(x)
model = models.Model(inputs, outputs)

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
    loss="categorical_crossentropy",
    metrics=["accuracy"],
)
model.summary()

callbacks = [
    tf.keras.callbacks.EarlyStopping(monitor="val_accuracy", patience=4, restore_best_weights=True),
    tf.keras.callbacks.ModelCheckpoint(
        os.path.join(MODEL_DIR, "best_model.h5"), monitor="val_accuracy", save_best_only=True
    ),
]

print("\n=== STAGE 1: Training classifier head (base frozen) ===")
model.fit(
    train_gen, validation_data=valid_gen, epochs=STAGE1_EPOCHS, callbacks=callbacks
)

# ---------------------------------------------------------------------
# STAGE 2: Fine-tune the top layers of MobileNetV2
# ---------------------------------------------------------------------
print("\n=== STAGE 2: Fine-tuning top layers of MobileNetV2 ===")
base_model.trainable = True
# Freeze everything except the last ~30 layers
for layer in base_model.layers[:-30]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
    loss="categorical_crossentropy",
    metrics=["accuracy"],
)

model.fit(
    train_gen, validation_data=valid_gen, epochs=STAGE2_EPOCHS, callbacks=callbacks
)

# ---------------------------------------------------------------------
# FINAL EVALUATION + SAVE
# ---------------------------------------------------------------------
loss, acc = model.evaluate(valid_gen)
print(f"\nFINAL VALIDATION ACCURACY: {acc * 100:.2f}%")
print(f"FINAL VALIDATION LOSS: {loss:.4f}")

final_path = os.path.join(MODEL_DIR, "plant_disease_model.h5")
model.save(final_path)
print(f"Saved final model to: {final_path}")
print("Next step: run convert_tflite.py")
