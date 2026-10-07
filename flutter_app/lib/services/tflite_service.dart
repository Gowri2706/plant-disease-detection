import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/disease_model.dart';

/// Wraps the TFLite interpreter and does everything needed to turn a
/// picked photo into a [DiseaseInfo] result (or null if the model is not
/// confident the image is a plant at all).
class TFLiteService {
  static const int inputSize = 224;

  // Below this confidence we refuse to answer -> "This is not a plant."
  // This mirrors exactly what predict.py does on the Python side, so
  // behaviour is consistent between testing and the real app.
  static const double confidenceThreshold = 0.60;

  Interpreter? _interpreter;
  List<String> _labels = [];
  Map<String, dynamic> _diseaseInfo = {};
  bool _isReady = false;

  bool get isReady => _isReady;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/plant_disease_model.tflite',
      );

      final labelsRaw = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsRaw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final infoRaw = await rootBundle.loadString('assets/disease_info.json');
      _diseaseInfo = json.decode(infoRaw) as Map<String, dynamic>;

      _isReady = true;
    } catch (e) {
      _isReady = false;
      throw Exception('Failed to load model/labels/disease info: $e');
    }
  }

  /// Returns a DiseaseInfo if confident enough, or null if the model
  /// thinks the image is not a recognisable plant leaf.
  Future<DiseaseInfo?> predict(File imageFile) async {
    if (!_isReady || _interpreter == null) {
      throw Exception('Model not loaded yet. Call loadModel() first.');
    }

    final bytes = await imageFile.readAsBytes();
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Could not decode image file.');
    }

    final resized = img.copyResize(
      decoded,
      width: inputSize,
      height: inputSize,
    );

    // Build normalized [1, 224, 224, 3] float32 input tensor
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    final numClasses = _labels.length;
    final output = List.generate(1, (_) => List.filled(numClasses, 0.0));

    _interpreter!.run(input, output);

    final scores = output[0];
    double maxScore = -1;
    int maxIndex = 0;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }

    if (maxScore < confidenceThreshold) {
      // Not confident enough -> treat as "not a plant / unclear photo"
      return null;
    }

    final classKey = _labels[maxIndex];
    final infoJson = _diseaseInfo[classKey] as Map<String, dynamic>? ?? {};
    return DiseaseInfo.fromJson(classKey, infoJson, maxScore);
  }

  void close() {
    _interpreter?.close();
  }
}
