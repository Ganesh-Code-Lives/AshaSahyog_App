import 'package:asha_sahyog/screens/smart_document_reader_screen.dart';
import 'package:asha_sahyog/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _documentText = 'Submit the form by 12 May.';

Future<void> _openVaultImage(
  WidgetTester tester, {
  String name = 'form.jpg',
  double textScale = 1,
}) async {
  SharedPreferences.setMockInitialValues({});
  const channel = MethodChannel('asha_sahyog/document_ocr');
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, (call) async {
    expect(call.method, 'recognize');
    return _documentText;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: SmartDocumentReaderScreen(
        initialFile: XFile.fromData(
          Uint8List.fromList([1]),
          path: name,
          name: name,
        ),
        initialExtension: 'jpg',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(
  WidgetTester tester,
  Finder target,
) => tester.scrollUntilVisible(
  target,
  150,
  scrollable: find
      .byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      )
      .first,
);

void main() {
  testWidgets(
    'shows AI controls directly and preserves the original after declined consent',
    (tester) async {
      await _openVaultImage(tester);

      expect(find.text('Scan Document'), findsOneWidget);
      expect(find.text('Upload Document'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
      await _scrollTo(tester, find.text('Listen to Document'));
      await _scrollTo(tester, find.widgetWithText(FilledButton, 'Play'));

      final simplify = find.widgetWithText(OutlinedButton, 'Simplify');
      await _scrollTo(tester, simplify);
      final translate = find.widgetWithText(OutlinedButton, 'Translate');
      expect(
        tester
            .widget<OutlinedButton>(simplify)
            .style!
            .foregroundColor!
            .resolve({}),
        AppTheme.pinkDark,
      );
      expect(
        tester
            .widget<OutlinedButton>(translate)
            .style!
            .foregroundColor!
            .resolve({}),
        const Color(0xFF15803D),
      );
      expect(
        tester.widget<Text>(find.text('Document AI')).style?.color,
        AppTheme.primaryDark,
      );
      expect(find.text('Output language'), findsOneWidget);
      await tester.tap(simplify);
      await tester.pumpAndSettle();
      expect(find.text('Send text to Google Gemini?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Waiting for Gemini…'), findsNothing);
      await _scrollTo(tester, find.text('Ask question'));
      await _scrollTo(tester, find.text('Original extracted text'));
      expect(find.text(_documentText), findsOneWidget);
    },
  );

  testWidgets(
    'fits equal import buttons and an accessible filename on a narrow phone',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final name = 'scaled_${List.filled(7, '0123456789abcdef').join()}.jpg';
      await _openVaultImage(tester, name: name, textScale: 2);

      final scan = find.widgetWithText(FilledButton, 'Scan Document');
      final upload = find.widgetWithText(OutlinedButton, 'Upload Document');
      final scanSize = tester.getSize(scan);
      expect(
        tester.widget<FilledButton>(scan).style!.backgroundColor!.resolve({}),
        const Color(0xFFFCE7F3),
      );
      expect(
        tester
            .widget<OutlinedButton>(upload)
            .style!
            .backgroundColor!
            .resolve({}),
        const Color(0xFFDBEAFE),
      );
      expect(tester.getSize(upload), scanSize);
      expect(tester.getTopLeft(scan).dy, tester.getTopLeft(upload).dy);
      expect(
        tester.getTopLeft(scan).dx,
        lessThan(tester.getTopLeft(upload).dx),
      );
      expect(scanSize.height, greaterThanOrEqualTo(48));
      expect(scanSize.width, greaterThanOrEqualTo(48));

      await _scrollTo(tester, find.text(name));
      expect(find.byTooltip(name), findsOneWidget);
      final filename = tester.widget<Text>(find.text(name));
      expect(filename.maxLines, 2);
      expect(filename.overflow, TextOverflow.ellipsis);
      await _scrollTo(tester, find.text('Text extracted'));
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      await _scrollTo(tester, find.text('Reading speed: 0.5'));
      await _scrollTo(tester, find.text('Output language'));
      await _scrollTo(tester, find.text('Ask question'));
      await _scrollTo(tester, find.text(_documentText));
      expect(tester.takeException(), isNull);
    },
  );
}
