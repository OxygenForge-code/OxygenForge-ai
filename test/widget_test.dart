import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oxygenforge_ai/main.dart';

void main() {
  testWidgets('OxygenForge AI welcome workspace renders', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const OxygenForgeApp());
    await tester.pumpAndSettle();

    expect(find.text('Görsel oluştur'), findsOneWidget);
    expect(find.text('Yaz veya düzenle'), findsOneWidget);
    expect(find.text('Web’de arama yap'), findsOneWidget);
    expect(find.text('OxygenForge AI’ye sor'), findsOneWidget);
  });
}
