import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_converter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PdfConverterApp());
    expect(find.byType(PdfConverterApp), findsOneWidget);
  });
}
