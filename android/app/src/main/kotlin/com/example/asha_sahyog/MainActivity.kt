package com.example.asha_sahyog

import android.graphics.BitmapFactory
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val app = applicationContext
        MethodChannel(
            messenger,
            "asha_sahyog/document_ocr",
            StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue()
        ).setMethodCallHandler { call, result ->
            if (call.method != "recognize") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val bytes = call.argument<ByteArray>("bytes")
            val script = call.argument<String>("script")
            if (bytes == null || bytes.isEmpty() || bytes.size > 20 * 1024 * 1024 ||
                (script != "latin" && script != "devanagari")) {
                result.error("invalid_image", "Choose a supported image under 20 MB.", null)
                return@setMethodCallHandler
            }

            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0 ||
                bounds.outWidth.toLong() * bounds.outHeight > 25_000_000L) {
                result.error("invalid_image", "Use a readable image under 25 megapixels.", null)
                return@setMethodCallHandler
            }

            var temporaryImage: File? = null
            try {
                val file = File.createTempFile("asha-reader-", ".img", app.cacheDir)
                temporaryImage = file
                file.writeBytes(bytes)
                // ML Kit handles EXIF orientation when reading a file URI.
                val image = InputImage.fromFilePath(app, Uri.fromFile(file))
                file.delete()
                val recognizer = if (script == "devanagari") {
                    TextRecognition.getClient(DevanagariTextRecognizerOptions.Builder().build())
                } else {
                    TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                }
                try {
                    recognizer.process(image).addOnCompleteListener { task ->
                        recognizer.close()
                        if (task.isSuccessful) {
                            result.success(task.result.text)
                        } else {
                            result.error("ocr_failed", "The image could not be read.", null)
                        }
                    }
                } catch (error: Exception) {
                    recognizer.close()
                    throw error
                }
            } catch (_: Exception) {
                temporaryImage?.delete()
                result.error("ocr_failed", "The image could not be read.", null)
            }
        }
    }
}
