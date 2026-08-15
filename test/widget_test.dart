import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oxygenforge_ai/app_theme.dart';
import 'package:oxygenforge_ai/main.dart';

void main() {
  testWidgets('OxygenForge AI welcome workspace renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const OxygenForgeApp());
    await tester.pumpAndSettle();

    expect(find.text('Bugün ne\nüreteceğiz?'), findsOneWidget);
    expect(find.text('OXYGENFORGE / ÇALIŞMA ALANI'), findsOneWidget);
    expect(find.text('Yeni çalışma'), findsNothing);
    expect(find.text('Bağlantılar'), findsOneWidget);
    expect(find.text('Kamera'), findsOneWidget);
    expect(find.byType(FrostedPanel), findsWidgets);
    expect(find.text('Ask OxygenForge AI…'), findsOneWidget);
  });
}
