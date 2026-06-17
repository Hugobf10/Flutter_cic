import Flutter
import UIKit
import Vision

final class NativeOcrChannel {
  static let name = "com.cicancer.cic_odoo_app/native_ocr"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeTextFromImage" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String,
        !path.isEmpty
      else {
        result(FlutterError(code: "invalid_path", message: "Ruta de imagen vacía.", details: nil))
        return
      }

      recognize(path: path, result: result)
    }
  }

  private static func recognize(path: String, result: @escaping FlutterResult) {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      result(FlutterError(code: "invalid_image", message: "No se pudo abrir la imagen.", details: nil))
      return
    }

    let request = VNRecognizeTextRequest { request, error in
      if let error = error {
        complete(result, FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
        return
      }

      let text = (request.results as? [VNRecognizedTextObservation])?
        .compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n") ?? ""
      complete(result, text)
    }

    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["es-ES", "en-US"]

    DispatchQueue.global(qos: .userInitiated).async {
      let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
      do {
        try handler.perform([request])
      } catch {
        complete(result, FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil))
      }
    }
  }

  private static func complete(_ result: @escaping FlutterResult, _ value: Any?) {
    DispatchQueue.main.async {
      result(value)
    }
  }
}
