#!/usr/bin/env python3
"""
GuaverRoots - Crop Disease Model Training Script

Trains a TensorFlow Lite model for Ghana vegetable disease detection
using transfer learning on MobileNetV2.

Usage:
    python train_model.py --dataset_dir /path/to/dataset --epochs 20 --output models/crop_disease_model.tflite

Dataset structure expected:
    dataset_dir/
        Corn/
            Corn___Cercospora_leaf_spot Gray_leaf_spot/
            Corn___Common_rust/
            Corn___Northern_Leaf_Blight/
            Corn___healthy/
        Pepper,_bell/
            Pepper,_bell___Bacterial_spot/
            Pepper,_bell___healthy/
        Cassava/
            Cassava___Bacterial_blight/
            Cassava___Brown_streak/
            Cassava___Green_mite/
            Cassava___Mosaic/
            Cassava___healthy/
        Garden_Egg/
            Garden_Egg___Fusarium_wilt/
            Garden_Egg___Aphid_transmitted_virus/
            Garden_Egg___healthy/
        Okra/
            Okra___Yellow_vein_mosaic/
            Okra___Fusarium_wilt/
            Okra___Damping_off/
            Okra___healthy/
        Yam/
            Yam___Mosaic/
            Yam___Anthracnose/
            Yam___Cocks_crow/
            Yam___healthy/
        Tomato/
            Tomato___Bacterial_spot/
            Tomato___Early_blight/
            Tomato___Late_blight/
            Tomato___Leaf_Mold/
            Tomato___Septoria_leaf_spot/
            Tomato___Spider_mites Two-spotted_spider_mite/
            Tomato___Target_Spot/
            Tomato___Tomato_mosaic_virus/
            Tomato___healthy/
        Squash/
            Squash___Powdery_mildew/
        Soybean/
            Soybean___healthy/
        Background_without_leaves/
"""

import os
import argparse
import json
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint


def parse_args():
    parser = argparse.ArgumentParser(description="Train GuaverRoots crop disease model")
    parser.add_argument("--dataset_dir", type=str, required=True, help="Path to dataset directory")
    parser.add_argument("--output", type=str, default="models/crop_disease_model.tflite", help="Output TFLite model path")
    parser.add_argument("--epochs", type=int, default=30, help="Number of training epochs")
    parser.add_argument("--batch_size", type=int, default=32, help="Batch size")
    parser.add_argument("--img_size", type=int, default=224, help="Input image size")
    parser.add_argument("--learning_rate", type=float, default=0.0001, help="Learning rate")
    parser.add_argument("--fine_tune", action="store_true", help="Fine-tune top layers of base model")
    parser.add_argument("--validation_split", type=float, default=0.2, help="Validation split ratio")
    parser.add_argument("--augment", action="store_true", default=True, help="Enable data augmentation")
    return parser.parse_args()


def create_class_names(labels_dir):
    """Load class names from labels.txt file."""
    labels_file = os.path.join(labels_dir, "labels.txt")
    if os.path.exists(labels_file):
        with open(labels_file, "r") as f:
            class_names = [line.strip() for line in f if line.strip()]
        return class_names
    return None


def build_data_generators(dataset_dir, img_size, batch_size, validation_split):
    """Create training and validation data generators with augmentation."""
    train_datagen = ImageDataGenerator(
        rescale=1.0 / 255.0,
        rotation_range=40,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        vertical_flip=True,
        brightness_range=[0.8, 1.2],
        fill_mode="nearest",
        validation_split=validation_split,
    )

    val_datagen = ImageDataGenerator(
        rescale=1.0 / 255.0,
        validation_split=validation_split,
    )

    train_generator = train_datagen.flow_from_directory(
        dataset_dir,
        target_size=(img_size, img_size),
        batch_size=batch_size,
        class_mode="categorical",
        subset="training",
        shuffle=True,
    )

    val_generator = val_datagen.flow_from_directory(
        dataset_dir,
        target_size=(img_size, img_size),
        batch_size=batch_size,
        class_mode="categorical",
        subset="validation",
        shuffle=False,
    )

    class_names = list(train_generator.class_indices.keys())
    num_classes = len(class_names)

    return train_generator, val_generator, class_names, num_classes


def build_model(num_classes, img_size, fine_tune=False):
    """Build a MobileNetV2-based transfer learning model."""
    base_model = MobileNetV2(
        input_shape=(img_size, img_size, 3),
        include_top=False,
        weights="imagenet",
        pooling="avg",
    )

    base_model.trainable = False

    if fine_tune:
        fine_tune_at = 100
        for layer in base_model.layers[:fine_tune_at]:
            layer.trainable = False
        for layer in base_model.layers[fine_tune_at:]:
            layer.trainable = True

    model = keras.Sequential(
        [
            base_model,
            layers.Dropout(0.3),
            layers.BatchNormalization(),
            layers.Dense(256, activation="relu"),
            layers.Dropout(0.4),
            layers.Dense(128, activation="relu"),
            layers.Dropout(0.3),
            layers.Dense(num_classes, activation="softmax"),
        ]
    )

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.0001),
        loss="categorical_crossentropy",
        metrics=["accuracy"],
    )

    return model


def train(model, train_generator, val_generator, epochs, callbacks):
    """Train the model."""
    history = model.fit(
        train_generator,
        validation_data=val_generator,
        epochs=epochs,
        callbacks=callbacks,
        verbose=1,
    )
    return history


def evaluate(model, val_generator):
    """Evaluate model on validation set."""
    loss, accuracy = model.evaluate(val_generator, verbose=0)
    print(f"Validation Loss: {loss:.4f}")
    print(f"Validation Accuracy: {accuracy * 100:.2f}%")
    return loss, accuracy


def convert_to_tflite(keras_model, output_path, class_names):
    """Convert Keras model to TFLite format."""
    converter = tf.lite.TFLiteConverter.from_keras_model(keras_model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]

    if converter.target_spec.supported_ops:
        converter.target_spec.supported_ops.append(tf.lite.OpsSet.SELECT_TF_OPS)

    tflite_model = converter.convert()

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(tflite_model)

    print(f"TFLite model saved to {output_path}")
    print(f"Model size: {len(tflite_model) / 1024 / 1024:.2f} MB")

    labels_path = os.path.join(os.path.dirname(output_path), "..", "labels", "labels.txt")
    labels_path = os.path.normpath(labels_path)
    with open(labels_path, "w") as f:
        for name in class_names:
            f.write(f"{name}\n")
    print(f"Labels saved to {labels_path}")


def main():
    args = parse_args()

    print("=" * 60)
    print("GuaverRoots Crop Disease Model Training")
    print("=" * 60)

    if not os.path.isdir(args.dataset_dir):
        print(f"Error: Dataset directory not found: {args.dataset_dir}")
        print(f"Please organize your images into subdirectories by class name.")
        return

    print(f"\nDataset directory: {args.dataset_dir}")
    print(f"Output path: {args.output}")
    print(f"Epochs: {args.epochs}")
    print(f"Batch size: {args.batch_size}")
    print(f"Image size: {args.img_size}x{args.img_size}")
    print(f"Fine-tuning: {args.fine_tune}")

    print("\nBuilding data generators...")
    train_gen, val_gen, class_names, num_classes = build_data_generators(
        args.dataset_dir, args.img_size, args.batch_size, args.validation_split
    )

    print(f"\nClasses ({num_classes}): {class_names}")
    print(f"Training samples: {train_gen.samples}")
    print(f"Validation samples: {val_gen.samples}")

    print("\nBuilding model...")
    model = build_model(num_classes, args.img_size, args.fine_tune)
    model.summary()

    callbacks = [
        EarlyStopping(
            monitor="val_loss",
            patience=5,
            restore_best_weights=True,
            verbose=1,
        ),
        ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=3,
            min_lr=1e-7,
            verbose=1,
        ),
        ModelCheckpoint(
            filepath="checkpoints/best_model.keras",
            monitor="val_accuracy",
            save_best_only=True,
            verbose=1,
        ),
    ]

    os.makedirs("checkpoints", exist_ok=True)

    print("\nStarting training...")
    history = train(model, train_gen, val_gen, args.epochs, callbacks)

    print("\nEvaluating model...")
    evaluate(model, val_gen)

    print("\nConverting to TFLite...")
    convert_to_tflite(model, args.output, class_names)

    print("\nTraining complete!")


if __name__ == "__main__":
    main()