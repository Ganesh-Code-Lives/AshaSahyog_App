import 'dart:math' as math;
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

enum DocumentScript {
  latin('English / Latin'),
  devanagari('Hindi and Marathi / Devanagari');

  const DocumentScript(this.label);
  final String label;
}

class ExtractedDocument {
  const ExtractedDocument({required this.text, required this.unreadablePages});

  final String text;
  final List<int> unreadablePages;
}

class DocumentReadException implements Exception {
  const DocumentReadException(this.message);
  final String message;
}

class DocumentExtractionService {
  static const maxBytes = 20 * 1024 * 1024;
  static const maxPages = 50;
  static const _ocrChannel = MethodChannel('asha_sahyog/document_ocr');
  static Future<void>? _pdfInitialization;

  bool get supportsImageOcr =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool supportsExtension(String extension) =>
      const {'pdf', 'jpg', 'jpeg', 'png'}.contains(extension.toLowerCase());

  Future<ExtractedDocument> extract(
    Uint8List bytes, {
    required String extension,
    required DocumentScript script,
    bool Function()? isCancelled,
  }) async {
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw const DocumentReadException('Choose a non-empty file under 20 MB.');
    }
    if (!supportsExtension(extension)) {
      throw const DocumentReadException('Choose a PDF, JPG or PNG file.');
    }
    if (extension.toLowerCase() != 'pdf') {
      final text = await _recognize(bytes, script);
      if (text.isEmpty) {
        throw const DocumentReadException(
          'No text found. Try a sharper image or choose the correct OCR script.',
        );
      }
      return ExtractedDocument(text: text, unreadablePages: const []);
    }

    await (_pdfInitialization ??= pdfrxFlutterInitialize().catchError((
      Object error,
      StackTrace stack,
    ) {
      _pdfInitialization = null;
      Error.throwWithStackTrace(error, stack);
    }));
    final document = await PdfDocument.openData(bytes);
    try {
      if (document.pages.length > maxPages) {
        throw const DocumentReadException(
          'Choose a PDF with 50 pages or fewer.',
        );
      }
      final pages = <String>[];
      final unreadable = <int>[];
      for (final page in document.pages) {
        if (isCancelled?.call() ?? false) break;
        var text = (await page.loadText())?.fullText.trim() ?? '';
        // Some scans contain an empty, invisible, or unusable text layer.
        if (!_hasUsableText(text)) {
          text = '';
          if (supportsImageOcr) {
            try {
              text = await _recognizePage(page, script);
            } on DocumentReadException {
              // A failed OCR page should not hide readable pages in a mixed PDF.
            }
          }
        }
        if (text.isEmpty) {
          unreadable.add(page.pageNumber);
        } else {
          pages.add('Page ${page.pageNumber}\n$text');
        }
      }
      if (pages.isEmpty) {
        throw DocumentReadException(
          supportsImageOcr
              ? 'No readable text found. Try a clearer scan or another OCR script.'
              : 'This PDF has no readable text layer. Scanned PDFs require Android.',
        );
      }
      return ExtractedDocument(
        text: pages.join('\n\n'),
        unreadablePages: List.unmodifiable(unreadable),
      );
    } finally {
      await document.dispose();
    }
  }

  bool _hasUsableText(String text) =>
      RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(text);

  Future<String> _recognizePage(PdfPage page, DocumentScript script) async {
    final scale = 2200 / math.max(page.width, page.height);
    final raster = await page.render(
      fullWidth: math.max(1.0, page.width * scale),
      fullHeight: math.max(1.0, page.height * scale),
    );
    if (raster == null) return '';
    try {
      final image = await raster.createImage();
      try {
        final png = await image.toByteData(format: ImageByteFormat.png);
        if (png == null) return '';
        return await _recognize(
          png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
          script,
        );
      } finally {
        image.dispose();
      }
    } finally {
      raster.dispose();
    }
  }

  Future<String> _recognize(Uint8List bytes, DocumentScript script) async {
    if (!supportsImageOcr) {
      throw const DocumentReadException('Image OCR is available on Android.');
    }
    try {
      final text = await _ocrChannel.invokeMethod<String>('recognize', {
        'bytes': bytes,
        'script': script.name,
      });
      return text?.trim() ?? '';
    } on PlatformException catch (error) {
      throw DocumentReadException(error.message ?? 'Image OCR failed.');
    }
  }
}
