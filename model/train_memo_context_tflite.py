import json
import math
import random
import re
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
import tensorflow as tf


ROOT = Path(__file__).resolve().parents[1]
TRAINING_DATA_PATH = ROOT / "model" / "data" / "memo_context_examples.json"
OUT_DIR = ROOT / "assets" / "models"
MODEL_PATH = OUT_DIR / "memo_context_classifier.tflite"
METADATA_PATH = OUT_DIR / "memo_context_metadata.json"

LABELS = ["일정", "할 일", "아이디어", "공부", "업무", "건강", "여행", "재정", "개인", "일기"]
FEATURE_SIZE = 1024
NGRAM_MIN = 1
NGRAM_MAX = 3
VALIDATION_FRACTION = 0.15
RANDOM_SEED = 42

KEYWORD_WEIGHTS = {
    "일정": {"일정": 2.4, "회의": 2.2, "미팅": 2.2, "약속": 2.0, "예약": 2.0, "수업": 1.8, "마감": 1.8, "제출": 1.6},
    "할 일": {"해야": 2.0, "할일": 2.0, "구매": 1.6, "사기": 1.6, "확인": 1.4, "정리": 1.3},
    "아이디어": {"아이디어": 2.2, "기획": 1.8, "컨셉": 1.7, "생각": 1.4, "개선": 1.3},
    "공부": {"공부": 2.2, "과제": 1.9, "시험": 1.8, "강의": 1.5, "복습": 1.5},
    "업무": {"업무": 2.0, "회사": 1.8, "프로젝트": 1.8, "보고서": 1.6, "메일": 1.4, "클라이언트": 1.4},
    "건강": {"건강": 2.0, "운동": 1.9, "병원": 1.8, "치과": 1.8, "식단": 1.5, "수면": 1.5},
    "여행": {"여행": 2.1, "항공": 1.8, "호텔": 1.8, "여권": 1.6, "공항": 1.6, "숙소": 1.6},
    "재정": {"결제": 1.9, "예산": 1.8, "지출": 1.8, "세금": 1.6, "보험료": 1.5, "납부": 1.5},
    "개인": {"기분": 1.6, "가족": 1.3, "하루": 1.5, "기록": 1.5, "생각": 1.4},
    "일기": {"일기": 2.0, "감정": 1.6, "다짐": 1.5, "하루": 1.4, "기록": 1.3},
}

FOLDER_COLORS = {
    "일정": 0xFF219EBC,
    "할 일": 0xFFE9C46A,
    "아이디어": 0xFFE56B6F,
    "공부": 0xFF6D597A,
    "업무": 0xFF457B9D,
    "건강": 0xFF588157,
    "여행": 0xFF2A9D8F,
    "재정": 0xFFD4A373,
    "개인": 0xFF8D99AE,
    "일기": 0xFFB5838D,
}


def normalize(value: str) -> str:
    return re.sub(r"[^가-힣a-z0-9]", "", value.lower())


def fnv1a(value: str) -> int:
    hash_value = 0x811C9DC5
    for char in value:
        hash_value ^= ord(char)
        hash_value = (hash_value * 0x01000193) & 0xFFFFFFFF
    return hash_value


def vectorize(texts):
    vectors = np.zeros((len(texts), FEATURE_SIZE), dtype=np.float32)
    for row, text in enumerate(texts):
        normalized = normalize(text)
        for n in range(NGRAM_MIN, NGRAM_MAX + 1):
            if len(normalized) < n:
                continue
            for start in range(0, len(normalized) - n + 1):
                bucket = fnv1a(normalized[start : start + n]) % FEATURE_SIZE
                vectors[row, bucket] += 1.0
        total = vectors[row].sum()
        if total > 0:
            vectors[row] = np.log1p(vectors[row]) / math.log1p(total)
    return vectors


def load_examples():
    raw_examples = json.loads(TRAINING_DATA_PATH.read_text(encoding="utf-8"))
    examples = [
        (item["label"], item["text"])
        for item in raw_examples
        if item.get("label") in LABELS and item.get("text")
    ]
    if not examples:
        raise RuntimeError(f"No training examples found in {TRAINING_DATA_PATH}")
    return examples


def build_model():
    model = tf.keras.Sequential(
        [
            tf.keras.layers.Input(shape=(FEATURE_SIZE,), name="hashed_char_ngrams"),
            tf.keras.layers.Dense(128, activation="relu"),
            tf.keras.layers.Dropout(0.25),
            tf.keras.layers.Dense(64, activation="relu"),
            tf.keras.layers.Dropout(0.15),
            tf.keras.layers.Dense(len(LABELS), activation="softmax", name="category"),
        ]
    )
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.003),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


def split_examples(examples):
    grouped = defaultdict(list)
    for label, text in examples:
        grouped[label].append((label, text))

    rng = random.Random(RANDOM_SEED)
    train = []
    validation = []

    for label in LABELS:
        items = grouped[label]
        rng.shuffle(items)
        validation_count = max(1, round(len(items) * VALIDATION_FRACTION))
        validation.extend(items[:validation_count])
        train.extend(items[validation_count:])

    rng.shuffle(train)
    rng.shuffle(validation)
    return train, validation


def to_arrays(examples):
    texts = [text for _, text in examples]
    labels = np.array([LABELS.index(label) for label, _ in examples], dtype=np.int32)
    return vectorize(texts), labels


def per_label_accuracy(model, x, y):
    predictions = model.predict(x, verbose=0).argmax(axis=1)
    totals = Counter()
    correct = Counter()

    for expected, actual in zip(y, predictions):
        label = LABELS[int(expected)]
        totals[label] += 1
        if expected == actual:
            correct[label] += 1

    return {
        label: {
            "accuracy": correct[label] / totals[label] if totals[label] else 0.0,
            "correct": correct[label],
            "total": totals[label],
        }
        for label in LABELS
    }


def main():
    np.random.seed(RANDOM_SEED)
    tf.random.set_seed(RANDOM_SEED)

    examples = load_examples()
    train_examples, validation_examples = split_examples(examples)
    x_train, y_train = to_arrays(train_examples)
    x_validation, y_validation = to_arrays(validation_examples)

    model = build_model()
    history = model.fit(
        x_train,
        y_train,
        validation_data=(x_validation, y_validation),
        epochs=180,
        batch_size=32,
        verbose=0,
        callbacks=[
            tf.keras.callbacks.EarlyStopping(
                monitor="val_accuracy",
                patience=18,
                restore_best_weights=True,
            ),
            tf.keras.callbacks.ReduceLROnPlateau(
                monitor="val_loss",
                factor=0.5,
                patience=8,
                min_lr=0.0002,
            ),
        ],
    )
    train_loss, train_accuracy = model.evaluate(x_train, y_train, verbose=0)
    validation_loss, validation_accuracy = model.evaluate(x_validation, y_validation, verbose=0)
    label_accuracy = per_label_accuracy(model, x_validation, y_validation)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = []
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
    tflite_model = converter.convert()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    MODEL_PATH.write_bytes(tflite_model)
    METADATA_PATH.write_text(
        json.dumps(
            {
                "version": 2,
                "algorithm": "tensorflow_lite_dense_hashed_char_ngrams",
                "labels": LABELS,
                "featureSize": FEATURE_SIZE,
                "ngramMin": NGRAM_MIN,
                "ngramMax": NGRAM_MAX,
                "keywordWeights": KEYWORD_WEIGHTS,
                "folderColors": FOLDER_COLORS,
                "trainingExamples": len(examples),
                "trainExamples": len(train_examples),
                "validationExamples": len(validation_examples),
                "validationFraction": VALIDATION_FRACTION,
                "epochsRun": len(history.history["loss"]),
                "trainingAccuracy": train_accuracy,
                "trainingLoss": train_loss,
                "validationAccuracy": validation_accuracy,
                "validationLoss": validation_loss,
                "perLabelValidationAccuracy": label_accuracy,
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )

    print(f"trained {len(examples)} examples")
    print(f"train split: {len(train_examples)}, validation split: {len(validation_examples)}")
    print(f"epochs run: {len(history.history['loss'])}")
    print(f"training accuracy: {train_accuracy:.3f}, loss: {train_loss:.3f}")
    print(f"validation accuracy: {validation_accuracy:.3f}, loss: {validation_loss:.3f}")
    print("per-label validation accuracy:")
    for label, metrics in label_accuracy.items():
        print(
            f"  {label}: {metrics['accuracy']:.3f} "
            f"({metrics['correct']}/{metrics['total']})"
        )
    print(f"wrote {MODEL_PATH} ({MODEL_PATH.stat().st_size} bytes)")
    print(f"wrote {METADATA_PATH}")


if __name__ == "__main__":
    main()
