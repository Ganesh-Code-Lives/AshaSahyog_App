import 'dart:convert';
import 'dart:io';

import 'package:asha_sahyog/services/document_extraction_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('asha_sahyog/document_ocr');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final service = DocumentExtractionService();

  setUpAll(() {
    // The Flutter test runner bundles native assets under build/native_assets.
    final name = switch (Platform.operatingSystem) {
      'macos' => 'libpdfium.dylib',
      'windows' => 'pdfium.dll',
      _ => 'libpdfium.so',
    };
    final pdfium = File(
      'build/native_assets/${Platform.operatingSystem}/$name',
    );
    expect(pdfium.existsSync(), isTrue, reason: 'Flutter must bundle PDFium.');
    Pdfrx.pdfiumModulePath = pdfium.absolute.path;
  });

  setUp(() {
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => '/tmp',
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('extracts selectable PDF text and reports unreadable pages', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final result = await service.extract(
      _mixedPdf(),
      extension: 'pdf',
      script: DocumentScript.latin,
    );

    expect(result.text, 'Page 1\nApplication closes on 12 May.');
    expect(result.unreadablePages, [2]);
  });

  test('sends only the image-only PDF page to Android OCR', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var ocrCalls = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      ocrCalls++;
      expect(call.method, 'recognize');
      expect(call.arguments['script'], 'devanagari');
      final png = call.arguments['bytes'] as Uint8List;
      expect(png.take(4), [137, 80, 78, 71]);
      return 'मराठी मजकूर';
    });

    final result = await service.extract(
      _mixedPdf(),
      extension: 'pdf',
      script: DocumentScript.devanagari,
    );

    expect(ocrCalls, 1);
    expect(
      result.text,
      'Page 1\nApplication closes on 12 May.\n\nPage 2\nमराठी मजकूर',
    );
    expect(result.unreadablePages, isEmpty);
  });

  test('rejects unsupported input without calling Android OCR', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await expectLater(
      service.extract(
        Uint8List.fromList([1]),
        extension: 'png',
        script: DocumentScript.latin,
      ),
      throwsA(
        isA<DocumentReadException>().having(
          (error) => error.message,
          'message',
          'Image OCR is available on Android.',
        ),
      ),
    );
  });
}

Uint8List _mixedPdf() {
  const text = 'BT /F1 14 Tf 18 155 Td (Application closes on 12 May.) Tj ET';
  // A second page with graphics and no selectable text.
  const imageOnly = '0 g 20 40 130 20 re f';
  const objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R 4 0 R] /Count 2 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 250 200] '
        '/Resources << /Font << /F1 7 0 R >> >> /Contents 5 0 R >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 250 200] '
        '/Contents 6 0 R >>',
  ];
  final all = [
    ...objects,
    '<< /Length ${text.length} >>\nstream\n$text\nendstream',
    '<< /Length ${imageOnly.length} >>\nstream\n$imageOnly\nendstream',
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];
  final pdf = StringBuffer('%PDF-1.4\n');
  final offsets = [0];
  for (var i = 0; i < all.length; i++) {
    offsets.add(pdf.length);
    pdf.writeln('${i + 1} 0 obj\n${all[i]}\nendobj');
  }
  final startXref = pdf.length;
  pdf.write('xref\n0 ${offsets.length}\n0000000000 65535 f \n');
  for (final offset in offsets.skip(1)) {
    pdf.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
  }
  pdf.write(
    'trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\n'
    'startxref\n$startXref\n%%EOF\n',
  );
  return Uint8List.fromList(ascii.encode(pdf.toString()));
}
