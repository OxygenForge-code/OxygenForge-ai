import 'package:flutter/material.dart';
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

    expect(
      find.text('Hangi konuda ilgili\nyardımcı olabilirim?'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.auto_awesome_rounded), findsAtLeastNWidgets(1));
    expect(find.text('OxygenForge AI’ye sor…'), findsOneWidget);
  });
}
