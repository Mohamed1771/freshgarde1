# FreshGuarde

A prototype for agricultural trade and refrigerated shipment monitoring, with a trained tomato maturity classifier.

**Stack:** Flutter, Material 3, Provider, Three.js, TensorFlow/Keras, MobileNetV2 and Google Colab.

## Features

- Trader registration, login and account settings.
- Agricultural marketplace and export shipment creation.
- Shipment tracking with a 3D refrigerated truck scene.
- Simulated temperature, humidity, produce condition and cooling alerts.
- Tomato maturity classification from uploaded images.

The Flutter application uses demo data and a rule-based transport simulation. The trained classifier runs independently in Colab; connecting it to Flutter requires additional backend integration.

## Project Files

| File or folder | Purpose |
|---|---|
| `lib/` | Flutter application and simulation logic |
| `assets/` | Images and Three.js truck scene |
| `Tomato_model.ipynb` | Training, error analysis, class merging and evaluation |
| `Deployment_Tomato.ipynb` | Image classification using the saved model |
| `tomato_mobilenetv2_5classes.keras.zip` | Trained five-class Keras model |
| `class_names.json` | Ordered class labels, exported by the training notebook |
| `tools/fastapi_server_example.py` | Reference server for future model integration |

## Tomato Maturity Model

The training notebook downloads version 2 of Roboflow project `tomato-maturity-ieee` in workspace `helmi-estiawan`, using COCO annotations. Tomato bounding boxes are cropped with a 5% margin and resized to **224 × 224**.

The prepared dataset contains **1,284 training**, **138 validation** and **69 test** tomato crops.

The classifier uses ImageNet-pretrained **MobileNetV2**, global average pooling, a 128-unit dense layer, dropout and softmax. Training has two stages: a frozen backbone with Adam at `1e-3`, followed by fine-tuning the last 30 layers at `1e-5`, with BatchNormalization frozen. Checkpoints and early stopping monitor validation loss.

### Class Merging and Results

The six-class model performed poorly on class 5 (F1: **0.45**). After examining misclassified images and samples from the later maturity classes, classes 5 and 6 were combined into `mature_merged`, and a new five-class model was trained.

Recorded test results from `Tomato_model.ipynb`:

| Metric | Six classes | Five classes |
|---|---:|---:|
| Accuracy | 81.16% | 95.65% |
| Macro precision | 82.97% | 95.42% |
| Macro recall | 82.04% | 96.75% |
| Macro F1 | 82.31% | 96.01% |

Both evaluations use 69 test crops. Merging changes the classification task, and augmentation and regularization also differ, so the improvement cannot be attributed to merging alone.

### Output Labels

Keep this order when interpreting predictions:

| Index | Training label | Proposed display name |
|---|---|---|
| 0 | class 1 | Mature Green |
| 1 | class 2 | Breaker |
| 2 | class 3 | Turning |
| 3 | class 4 | Pink |
| 4 | mature_merged | Light Red / Red |

The deployment notebook overrides the original labels with these display names. Verify their meaning against the dataset before adopting them; renaming labels requires no retraining, but reordering them produces incorrect labels.

## Run the Flutter App

From the project directory:

```bash
flutter pub get
flutter run -d chrome --release
```

For Android, start an emulator or connect a device and select its ID:

```bash
flutter devices
flutter run -d <device-id>
flutter build apk --release
```

Demo login: `ahmad@gmail.com` / `12345678`. Password-reset demo OTP: `123456`.

## Train in Colab

Open `Tomato_model.ipynb` in [Google Colab](https://colab.research.google.com/), select a GPU runtime and run the cells in order. Enter your Roboflow API key when prompted. The notebook installs its dataset and evaluation dependencies, trains both experiments, and exports the final model and `class_names.json`.

## Classify an Image

1. Place the supplied model archive and exported `class_names.json` in Google Drive's **My Drive** root, or adjust the paths in the notebook.
2. Open `Deployment_Tomato.ipynb` in Colab and mount Drive.
3. Run the model-loading and class-label cells.
4. Run the final cell to upload images and display the predicted class, confidence and all class probabilities.

Default paths:

```python
MODEL_PATH = "/content/drive/MyDrive/tomato_mobilenetv2_5classes.keras.zip"
CLASSES_PATH = "/content/drive/MyDrive/class_names.json"
```

The supplied archive directly contains the Keras model files. The notebook copies it to `/content/tomato_model.keras` and loads it with `compile=False`. Repeat only the final cell for more images in the same runtime; no retraining or model upload is needed.

**Input:** RGB images resized to 224 × 224, with float32 pixel values in `[0, 255]`. Do not divide by 255 or normalize again: rescaling is already inside the model.

## Integration and Limitations

- The classifier expects a tomato-focused image or crop. It does not detect individual tomatoes, reject non-tomato images or estimate shelf life, spoilage or cooling requirements.
- Colab inference is not a hosted API. Use the application's `AiInspectionService` integration layer and reference FastAPI server to implement a backend.
- The existing API maturity vocabulary differs from the model labels; reconcile that mapping before integration. Do not infer quality or defect measurements from maturity probabilities.
- Application data is stored in memory, and the transport simulation is illustrative rather than scientifically validated.

## Checks

```bash
flutter analyze
flutter test
```

The AI results above are saved notebook outputs; they were not regenerated for this README.
