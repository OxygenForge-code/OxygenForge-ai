import 'package:flutter/material.dart';

class OxygenForgeTheme {
  static const ink = Color(0xFF0B0D12);
  static const panel = Color(0xFF13161E);
  static const panelRaised = Color(0xFF191D27);
  static const line = Color(0xFF292E3A);
  static const muted = Color(0xFF858C9A);
  static const text = Color(0xFFF6F7FB);
  static const violet = Color(0xFF8B5CF6);
  static const violetBright = Color(0xFFA78BFA);
  static const cyan = Color(0xFF67E8F9);
  static const green = Color(0xFF6EE7B7);
  static const error = Color(0xFFF87171);

  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(
        surface: ink,
        surfaceContainer: panel,
        surfaceContainerHigh: panelRaised,
        primary: violetBright,
        secondary: cyan,
        onSurface: text,
        onPrimary: Colors.white,
        outline: line,
        error: error,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
        fontFamily: 'Inter',
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelRaised,
        hintStyle: const TextStyle(color: muted),
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: violetBright, width: 1.2),
        ),
      ),
      dividerColor: line,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panelRaised,
        contentTextStyle: const TextStyle(color: text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: panel,
        indicatorColor: violet.withValues(alpha: 0.15),
      ),
    );
  }
}

class ForgeGradient extends LinearGradient {
  const ForgeGradient({
    super.begin = Alignment.topLeft,
    super.end = Alignment.bottomRight,
    super.colors = const [OxygenForgeTheme.violet, OxygenForgeTheme.cyan],
  });
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? OxygenForgeTheme.panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? OxygenForgeTheme.line),
      ),
      child: child,
    );
  }
}
