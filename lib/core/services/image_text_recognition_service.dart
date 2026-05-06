import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ImageTextRecognitionService {
  Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final koreanRecognizer = TextRecognizer(
      script: TextRecognitionScript.korean,
    );
    final latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final results = await Future.wait([
        koreanRecognizer.processImage(inputImage),
        latinRecognizer.processImage(inputImage),
      ]);
      return _mergeRecognizedText(results).trim();
    } finally {
      await koreanRecognizer.close();
      await latinRecognizer.close();
    }
  }

  String _mergeRecognizedText(List<RecognizedText> results) {
    final lines = <String>[];
    final seen = <String>{};

    for (final result in results) {
      for (final block in result.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          final key = _normalizeForDedup(text);
          if (text.isNotEmpty && seen.add(key)) {
            lines.add(text);
          }
        }
      }
    }

    if (lines.isNotEmpty) return lines.join('\n');

    for (final result in results) {
      final text = result.text.trim();
      final key = _normalizeForDedup(text);
      if (text.isNotEmpty && seen.add(key)) {
        lines.add(text);
      }
    }
    return lines.join('\n');
  }

  String _normalizeForDedup(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }
}
