"""
=========================================================================
STEP: DATASET DOWNLOAD
=========================================================================
This script downloads the "New Plant Diseases Dataset (Augmented)" from
Kaggle. It is based on the well-known PlantVillage dataset and contains
~87,000 images across 38 plant/disease classes.

BEFORE RUNNING THIS FILE:
1. Create a free Kaggle account: https://www.kaggle.com
2. Go to: Profile picture -> Settings -> scroll down -> "Create New Token"
3. This downloads a file called kaggle.json
4. Place kaggle.json here:
      Windows: C:\\Users\\<YOUR_NAME>\\.kaggle\\kaggle.json
      Mac/Linux: ~/.kaggle/kaggle.json
      Google Colab: upload it when the script below asks for it

RUN:
    python download_dataset.py
=========================================================================
"""

import os
import subprocess
import sys

DATASET_SLUG = "vipoooool/new-plant-diseases-dataset"
DEST_DIR = os.path.join(os.path.dirname(__file__), "dataset")


def check_kaggle_credentials():
    home = os.path.expanduser("~")
    kaggle_json = os.path.join(home, ".kaggle", "kaggle.json")
    if not os.path.exists(kaggle_json):
        print("ERROR: kaggle.json not found at:", kaggle_json)
        print("Please follow the setup steps in the header comment of this file.")
        sys.exit(1)
    print("Found Kaggle credentials at:", kaggle_json)


def download():
    os.makedirs(DEST_DIR, exist_ok=True)
    print(f"Downloading dataset '{DATASET_SLUG}' into {DEST_DIR} ...")
    cmd = [
        "kaggle", "datasets", "download",
        "-d", DATASET_SLUG,
        "-p", DEST_DIR,
        "--unzip",
    ]
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print("Download failed. Check your internet connection and kaggle.json.")
        sys.exit(1)
    print("Download complete!")
    print("Dataset is now available inside:", DEST_DIR)


if __name__ == "__main__":
    check_kaggle_credentials()
    download()
