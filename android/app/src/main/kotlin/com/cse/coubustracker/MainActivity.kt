package com.cse.coubustracker

import android.util.Log
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "tesseract_ocr"
        ).setMethodCallHandler { call, result ->
            if (call.method == "extractText") {
                extractText(call, result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun extractText(call: MethodChannel.MethodCall, result: MethodChannel.Result) {
        try {
            val imagePath = call.argument<String>("imagePath") ?: ""
            val tessDataPath = call.argument<String>("tessDataPath") ?: ""
            val language = call.argument<String>("language") ?: "ben"

            val imageFile = File(imagePath)
            if (!imageFile.exists()) {
                result.error("IMAGE_NOT_FOUND", "Image file not found: $imagePath", null)
                return
            }

            val tessDataDir = File(tessDataPath, "tessdata")
            val trainedDataFile = File(tessDataDir, "$language.traineddata")
            if (!trainedDataFile.exists()) {
                result.error("TESSDATA_NOT_FOUND", "Trained data not found: ${trainedDataFile.absolutePath}", null)
                return
            }

            val tessBaseAPI = TessBaseAPI()
            val initialized = tessBaseAPI.init(tessDataPath, language)
            if (!initialized) {
                tessBaseAPI.recycle()
                result.error("INIT_FAILED", "Tesseract init failed for language: $language", null)
                return
            }

            tessBaseAPI.setImage(imageFile)
            val text = tessBaseAPI.utF8Text ?: ""
            tessBaseAPI.recycle()

            result.success(text)
        } catch (e: Exception) {
            Log.e("TesseractOCL", "Error extracting text", e)
            result.error("TESSERACT_ERROR", e.message, null)
        }
    }
}