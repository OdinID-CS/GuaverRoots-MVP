# GuaverRoots AI Training Workspace

Scalable folder structure for TensorFlow Lite crop disease model training.

## Structure

```
ai_training/
├── README.md
├── datasets/
│   ├── raw/          # Original images as collected from farmers
│   ├── processed/    # Preprocessed, resized, normalized images
│   └── augmented/    # Augmented training images (flips, rotations, etc.)
├── preprocessing/    # Image preprocessing scripts and configs
├── scripts/          # Training, evaluation, and inference scripts
├── models/           # Saved model checkpoints and weights
├── exports/          # Exported TFLite models after conversion
└── notebooks/        # Jupyter notebooks for EDA and experiments
```

## Dataset Requirements

- Images organized in class-labeled subdirectories
- Minimum ~100 images per class recommended
- Supported crops: Corn, Pepper (bell), Cassava, Garden Egg, Okra, Yam, Tomato, Squash, Soybean
- Include both diseased and healthy samples per crop

## Workflow

1. Collect/obtain images → `datasets/raw/`
2. Preprocess → `datasets/processed/`
3. Augment → `datasets/augmented/`
4. Train → `models/`
5. Export to TFLite → `exports/`