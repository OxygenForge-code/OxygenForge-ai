import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oxygenforge_ai/main.dart';

void main() {
  testWidgets('OxygenForge AI welcome workspace renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const OxygenForgeApp());
    await tester.pumpAndSettle();

    expect(find.text('Fikrini ateşle.'), findsOneWidget);
    expect(find.text('Yeni çalışma'), findsOneWidget);
    expect(find.text('OxygenForge AI\'ya sor…'), findsOneWidget);
  });
}
