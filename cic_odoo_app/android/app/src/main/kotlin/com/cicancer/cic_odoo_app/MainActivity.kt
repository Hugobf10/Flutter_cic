package com.cicancer.cic_odoo_app

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "com.cicancer.cic_odoo_app/native_ocr"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "recognizeTextFromImage") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val path = call.argument<String>("path")
                if (path.isNullOrBlank()) {
                    result.error("invalid_path", "Ruta de imagen vacía.", null)
                    return@setMethodCallHandler
                }

                try {
                    val uri = if (path.startsWith("content://") || path.startsWith("file://")) {
                        Uri.parse(path)
                    } else {
                        Uri.fromFile(File(path))
                    }
                    val image = InputImage.fromFilePath(this, uri)
                    val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

                    recognizer.process(image)
                        .addOnSuccessListener { visionText ->
                            result.success(visionText.text)
                            recognizer.close()
                        }
                        .addOnFailureListener { error ->
                            recognizer.close()
                            result.error(
                                "ocr_failed",
                                error.localizedMessage ?: "No se pudo leer la imagen.",
                                null
                            )
                        }
                } catch (error: Exception) {
                    result.error(
                        "ocr_failed",
                        error.localizedMessage ?: "No se pudo leer la imagen.",
                        null
                    )
                }
            }
    }
}
