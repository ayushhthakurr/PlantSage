import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class Classifier {
  late File imageFile;
  bool _modelLoaded = false;

  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/model/model_unquant.tflite",
        labels: "assets/model/labels.txt",
        numThreads: 1,
      );
      _modelLoaded = true;
    } catch (e) {
      print('Error loading model: $e');
      throw Exception('Failed to load TFLite model');
    }
  }

  Future<List?> getDisease(ImageSource imageSource) async {
    try {
      // Pick image
      final image = await ImagePicker().pickImage(
        source: imageSource,
        maxHeight: 224,
        maxWidth: 224,
      );

      if (image == null) return null;

      imageFile = File(image.path);

      // Load model if not already loaded
      if (!_modelLoaded) {
        await loadModel();
      }

      // Classify image
      var result = await classifyImage(imageFile);

      return result;
    } catch (e) {
      print('Error in getDisease: $e');
      return null;
    } finally {
      // Close model
      try {
        await Tflite.close();
        _modelLoaded = false;
      } catch (e) {
        print('Error closing model: $e');
      }
    }
  }

  Future<List?> classifyImage(File image) async {
    try {
      var output = await Tflite.runModelOnImage(
        path: image.path,
        imageMean: 0.0,
        imageStd: 255.0,
        numResults: 2,
        threshold: 0.2,
        asynch: true,
      );
      return output;
    } catch (e) {
      print('Error classifying image: $e');
      return null;
    }
  }
}