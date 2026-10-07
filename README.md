# 🌿 Plant Disease Detector — Full Setup Guide (Top to Bottom)

இது ஒரு complete AI plant disease detection project: Python-ல model train
பண்றது + Flutter app-ல அந்த model-ஐ use பண்றது. கீழே இருக்குற order-ல
follow பண்ணுங்க, ஒண்ணு skip பண்ணாதீங்க.

## ⚠️ Honest note (முக்கியம், தயவுசெய்து படிக்கவும்)
**"100% error-free / 100% accuracy" எந்த AI model-லயும் யாராலயும் guarantee
பண்ண முடியாது.** இந்த setup realistic ஆ ~95-97% validation accuracy
தரும் (PlantVillage dataset மேல). Real phone photos-ல (வெளிச்சம், background,
camera quality வேறுபடும்போது) accuracy கொஞ்சம் குறையலாம் — இது எல்லா
plant-disease app-லயும் நடக்குற normal விஷயம், இந்த code-ல bug இல்ல.
இதை குறைக்க இந்த project-ல 2 protections வெச்சிருக்கேன்:
1. **Confidence threshold (60%)** — model confident இல்லைனா "This is not
   a plant" காட்டும், தப்பான guess காட்டாது.
2. **Transfer learning + fine-tuning + data augmentation** — accuracy-ஐ
   maximize பண்ண.

---

## 📁 Folder Structure (இதுதான் இருக்கும்)

```
plant_disease_detection/
├── python_ai_model/
│   ├── requirements.txt          # Python libraries list
│   ├── download_dataset.py       # STEP 1: Kaggle-ல இருந்து dataset download
│   ├── train.py                  # STEP 2: Model training (MobileNetV2)
│   ├── convert_tflite.py         # STEP 3: .h5 -> .tflite convert
│   ├── predict.py                # STEP 4: single image test (optional but recommended)
│   ├── disease_info.json         # 38 diseases-க்கும் Tamil+English தகவல்
│   ├── dataset/                  # (download பண்ணப்பட்டதும் இங்க வரும்)
│   └── model/                    # (train பண்ணப்பட்டதும் இங்க .h5/.tflite வரும்)
│
├── flutter_app/
│   ├── pubspec.yaml               # Flutter dependencies
│   ├── assets/
│   │   ├── disease_info.json      # (already copied)
│   │   ├── plant_disease_model.tflite   # ⚠️ நீங்க copy பண்ணணும் (Step below)
│   │   └── labels.txt                   # ⚠️ நீங்க copy பண்ணணும் (Step below)
│   └── lib/
│       ├── main.dart
│       ├── models/disease_model.dart
│       ├── services/language_provider.dart   # Tamil/English toggle logic
│       ├── services/tflite_service.dart      # AI inference logic (core "brain")
│       └── screens/home_screen.dart          # Camera/Gallery pick UI
│       └── screens/result_screen.dart        # Prediction result UI
│
└── README.md   (இந்த file)
```

---

# 🅰️ PART 1 — PYTHON: TRAIN THE MODEL

## Step 1: Python environment setup
Python 3.10 அல்லது 3.11 இல்லைனா முதல்ல [python.org](https://python.org)
இருந்து install பண்ணுங்க. அப்புறம் terminal/cmd திறந்து:

```bash
cd plant_disease_detection/python_ai_model

python -m venv venv
venv\Scripts\activate        # Windows
source venv/bin/activate     # Mac/Linux

pip install -r requirements.txt
```

## Step 2: Kaggle API key setup (dataset download பண்ண இது தேவை)
1. https://www.kaggle.com → free account create/login பண்ணுங்க
2. Profile picture → **Settings** → கீழே scroll → **"Create New Token"**
3. `kaggle.json` file download ஆகும். இது இப்படி இருக்கும்:
   ```json
   {"username":"yourname","key":"abcd1234..."}
   ```
4. அந்த file-ஐ இங்க வையுங்க:
   - Windows: `C:\Users\<YOUR_NAME>\.kaggle\kaggle.json`
   - Mac/Linux: `~/.kaggle/kaggle.json`
   - `.kaggle` folder இல்லைனா புதுசா create பண்ணுங்க

## Step 3: Dataset download
```bash
python download_dataset.py
```
இது "New Plant Diseases Dataset (Augmented)" (~87,000 images, 38 classes,
~1.5GB) Kaggle-ல இருந்து download பண்ணி `dataset/` folder-க்குள் போடும்.

## Step 4: Training — Google Colab recommend பண்றேன் (free GPU, வேகமா முடியும்)

Local PC-ல GPU இல்லைனா training 4-8 மணி நேரம் ஆகலாம். Colab-ல
**30-60 நிமிடத்துல** முடிஞ்சிடும்.

1. https://colab.research.google.com → New Notebook
2. **Runtime → Change runtime type → T4 GPU** select பண்ணி Save
3. இடது side **Files (📁)** icon → உங்க `python_ai_model` folder full-ஆ
   zip பண்ணி upload பண்ணி, Colab-ல unzip பண்ணுங்க (அல்லது drag & drop)
4. கீழ code cells-ஐ **ஒவ்வொண்ணா** run பண்ணுங்க:

```python
!pip install -q kaggle tensorflow==2.15.0 pillow scikit-learn
```

```python
from google.colab import files
files.upload()   # kaggle.json select பண்ணுங்க
!mkdir -p ~/.kaggle
!cp kaggle.json ~/.kaggle/
!chmod 600 ~/.kaggle/kaggle.json
```

```python
%cd python_ai_model
!python download_dataset.py
```

```python
!python train.py
```

Training முடிஞ்சதும் இது காட்டும்:
```
FINAL VALIDATION ACCURACY: 96.xx%
```

5. இடது **Files panel** → `model/` folder → `plant_disease_model.h5` மற்றும்
   `class_indices.json` — இரண்டையும் **right-click → Download** பண்ணி
   உங்க local `python_ai_model/model/` folder-க்கு கொண்டு வாங்க.

## Step 5: Model test பண்ணுங்க (optional ஆனா highly recommended)
```bash
python predict.py path/to/any_leaf_photo.jpg
```
இது terminal-லயே prediction, confidence %, "not a plant" logic எல்லாம்
காட்டும். இதுல சரியா வந்தா தான் Flutter app-லயும் சரியா வரும்.

## Step 6: TFLite-க்கு convert (local PC-ல, .h5 file வெச்சு)
```bash
python convert_tflite.py
```
இது create பண்ணும் (`model/` folder-க்குள்):
- `plant_disease_model.tflite` ← Flutter-க்கு தேவை
- `labels.txt` ← Flutter-க்கு தேவை

---

# 🅱️ PART 2 — FLUTTER: BUILD THE APP (Android Studio)

## Step 0: Flutter SDK install
1. https://docs.flutter.dev/get-started/install → உங்க OS-க்கான SDK
   download பண்ணுங்க
2. Android Studio → **Settings/Preferences → Plugins** → "Flutter" search
   பண்ணி install பண்ணுங்க (Dart auto வரும்)
3. Terminal-ல:
```bash
flutter doctor
```
எல்லாம் ✅ tick வர வேண்டியது.

## Step 1: Native android/ folder generate பண்ணணும் (இந்த zip-ல இல்ல, IMPORTANT)
```bash
cd plant_disease_detection/flutter_app
flutter create --platforms=android .
```
இது `lib/`, `pubspec.yaml`-ஐ overwrite பண்ணாம missing `android/` folder
மட்டும் புதுசா add பண்ணும்.

## Step 2: AI model files-ஐ assets-க்கு copy பண்ணுங்க
```
python_ai_model/model/plant_disease_model.tflite  →  flutter_app/assets/
python_ai_model/model/labels.txt                   →  flutter_app/assets/
```
(`disease_info.json` already `flutter_app/assets/`-ல இருக்கு — நான்
ஏற்கனவே அங்க வெச்சிருக்கேன்.)

Copy ஆனதும் `flutter_app/assets/` இப்படி இருக்கணும்:
```
assets/
  plant_disease_model.tflite
  labels.txt
  disease_info.json
```

## Step 3: Android Studio-ல open பண்ணுங்க
`File → Open →` `flutter_app` folder select பண்ணுங்க.

## Step 4: `android/app/build.gradle` edit பண்ணணும்
Left panel → `android` → `app` → `build.gradle` (அல்லது `build.gradle.kts`)
திறங்க. `minSdkVersion` / `minSdk` குறைந்தது **21** இருக்கணும்:

**Groovy (`build.gradle`):**
```gradle
android {
    defaultConfig {
        minSdkVersion 21
        ...
    }
}
```

**Kotlin DSL (`build.gradle.kts`):**
```kotlin
android {
    defaultConfig {
        minSdk = 21
        ...
    }
}
```

## Step 5: Dependencies install
Android Studio கீழ **Terminal** tab-ல:
```bash
flutter pub get
```
"Got dependencies!" message வரணும்.

## Step 6: Run பண்ணுங்க
1. மேல toolbar device selector-ல **Emulator** (Device Manager → create
   ஒண்ணு) அல்லது **USB phone** (Developer options → USB debugging ON)
   select பண்ணுங்க
2. Green ▶️ **Run** button click பண்ணுங்க, அல்லது:
```bash
flutter run
```

App திறந்ததும் — camera/gallery buttons + "தமிழ்/EN" toggle top-right-ல
வரணும். Photo எடுத்தா/பதிவேற்றினா, 1-2 விநாடியில் result screen-ல
disease name + description + solution (selected language-ல) காட்டும்.
Confidence 60%-க்கு கீழ இருந்தா **"This is not a plant."** காட்டும்.

---

## 🛠️ Common Errors & Fixes

| Error | Fix |
|---|---|
| `Unable to locate a Dart SDK` | Android Studio settings-ல Flutter SDK path சரியா set பண்ணுங்க |
| `minSdkVersion` conflict | Step 4-ல சொன்னா மாதிரி 21+ ஆக்குங்க |
| `Asset not found: assets/plant_disease_model.tflite` | Step 2 copy சரியா பண்ணீங்களான்னு பாருங்க, `pubspec.yaml` path spelling சரிபாருங்க |
| `flutter: command not found` | Flutter SDK-ஐ system PATH-ல add பண்ணுங்க |
| Kaggle 403/401 error | `kaggle.json` சரியான location-ல இருக்கான்னு பாருங்க |
| Training accuracy குறைவா இருந்தா (<90%) | STAGE1_EPOCHS/STAGE2_EPOCHS `train.py`-ல அதிகரிக்கவும், அல்லது dataset முழுசா download ஆகுதான்னு check பண்ணுங்க |
| App-ல prediction எல்லாம் "not a plant" வருது | `TFLiteService.confidenceThreshold` (0.60) கொஞ்சம் குறைச்சு பாருங்க (`tflite_service.dart`) — ஆனா ரொம்ப குறைச்சா தப்பான guess வரலாம் |
| Model loading crash on real device | `labels.txt` order train.py-ல save பண்ண `class_indices.json` order-க்கு match ஆகுதான்னு உறுதி பண்ணுங்க |

---

## 🎯 Accuracy Reality Check (please read before showing this to anyone)
- Validation accuracy (lab images, clean background): **~95-97%** realistic
  target with this exact setup.
- Real-world photos (busy background, poor light, blurry): typically
  **10-20% lower** than the lab number — this is universal to every
  image-classification app, not specific to this code.
- **No developer, tool, or company can promise 100% prediction accuracy
  on real-world photos.** The confidence-threshold "not a plant" safety
  check in this project exists specifically to reduce wrong answers by
  refusing to guess when the model isn't sure — that is the honest,
  professional way to handle this, not a workaround for missing accuracy.

Ethachum error வந்தா, exact error message full-ஆ paste பண்ணுங்க —
step by step debug பண்ணி தர்றேன்.
