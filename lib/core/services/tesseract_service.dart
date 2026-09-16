import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class TesseractService {
  static const _channel = MethodChannel('tesseract_ocr');
  static bool _initialized = false;
  static String? _tessDataPath;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final tessDataDir = Directory('${appDir.path}/tessdata');

      if (!await tessDataDir.exists()) {
        await tessDataDir.create(recursive: true);
      }

      final trainedDataFile = File('${tessDataDir.path}/ben.traineddata');
      if (!await trainedDataFile.exists()) {
        final data = await rootBundle.load('assets/tessdata/ben.traineddata');
        await trainedDataFile.writeAsBytes(data.buffer.asUint8List());
      }

      _tessDataPath = appDir.path;
      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  static Future<String> extractBanglaText(String imagePath) async {
    await init();

    if (!_initialized || _tessDataPath == null) return '';

    try {
      final result = await _channel.invokeMethod<String>(
        'extractText',
        {
          'imagePath': imagePath,
          'tessDataPath': _tessDataPath,
          'language': 'ben',
        },
      );
      return result ?? '';
    } catch (e) {
      return '';
    }
  }
}
