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

    expect(find.text('Nasıl yardımcı olabilirim?'), findsOneWidget);
    expect(find.text('Yeni çalışma'), findsAtLeastNWidgets(1));
    expect(find.text('Kod veya analiz'), findsOneWidget);
    expect(find.text('Plan oluştur'), findsOneWidget);
    expect(find.text('Mesaj yaz…'), findsOneWidget);
  });
}
