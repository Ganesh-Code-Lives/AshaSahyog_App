import 'package:asha_sahyog/screens/smart_document_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'opens a Vault image and preserves it when AI consent is declined',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const channel = MethodChannel('asha_sahyog/document_ocr');
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'recognize');
        return 'Submit the form by 12 May.';
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: SmartDocumentReaderScreen(
            initialFile: XFile.fromData(
              Uint8List.fromList([1]),
              name: 'form.jpg',
            ),
            initialExtension: 'jpg',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scan Document'), findsOneWidget);
      expect(find.text('Upload Document'), findsOneWidget);
      expect(find.text('Original extracted text'), findsOneWidget);
      expect(find.text('Submit the form by 12 May.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Play'), findsOneWidget);

      final ai = find.text('Document AI');
      await tester.ensureVisible(ai);
      await tester.tap(ai);
      await tester.pumpAndSettle();
      final simplify = find.widgetWithText(OutlinedButton, 'Simplify');
      await tester.ensureVisible(simplify);
      await tester.tap(simplify);
      await tester.pumpAndSettle();

      expect(find.text('Send text to Google Gemini?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Waiting for Gemini…'), findsNothing);
      expect(
        find.text('Document AI is unavailable. Try again later.'),
        findsNothing,
      );
      await tester.ensureVisible(find.text('Original extracted text'));
      expect(find.text('Submit the form by 12 May.'), findsOneWidget);
    },
  );
}
