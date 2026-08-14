import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oxygenforge_ai/app_theme.dart';

void main() {
  test('OxygenForge renk tokenları ve Material teması monokrom kalır', () {
    final theme = OxygenForgeTheme.build();

    expect(OxygenForgeTheme.ink, Colors.black);
    expect(OxygenForgeTheme.text, Colors.white);
    expect(OxygenForgeTheme.violet, Colors.white);
    expect(OxygenForgeTheme.cyan, Colors.white);
    expect(OxygenForgeTheme.green, Colors.white);
    expect(OxygenForgeTheme.error, Colors.white);
    expect(theme.scaffoldBackgroundColor, Colors.black);
    expect(theme.colorScheme.primary, Colors.white);
    expect(theme.colorScheme.onPrimary, Colors.black);
  });
}
