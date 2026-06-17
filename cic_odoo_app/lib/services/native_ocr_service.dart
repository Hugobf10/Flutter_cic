import 'package:flutter/services.dart';

class NativeOcrService {
  static const MethodChannel _channel = MethodChannel(
    'com.cicancer.cic_odoo_app/native_ocr',
  );

  Future<String> recognizeTextFromImage(String imagePath) async {
    final text = await _channel.invokeMethod<String>(
      'recognizeTextFromImage',
      {'path': imagePath},
    );
    return text ?? '';
  }
}
