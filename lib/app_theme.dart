import 'dart:ui';

import 'package:flutter/material.dart';

class OxygenForgeTheme {
  static const ink = Colors.black;
  static const panel = Color(0xFF080808);
  static const panelRaised = Color(0xFF111111);
  static const line = Color(0xFF3A3A3A);
  static const muted = Color(0xFFB8B8B8);
  static const text = Colors.white;
  static const violet = Colors.white;
  static const violetBright = Colors.white;
  static const cyan = Colors.white;
  static const green = Colors.white;
  static const error = Colors.white;

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
        onPrimary: Colors.black,
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
    super.colors = const [Colors.white, Colors.white],
  });
}

class FrostedPanel extends StatelessWidget {
  const FrostedPanel({
    required this.child,
    required this.borderRadius,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderColor,
    this.blur = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? color;
  final Color? borderColor;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? const Color(0xB30A0A0A),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x18FFFFFF), Color(0x05000000)],
            ),
            borderRadius: borderRadius,
            border: Border.all(color: borderColor ?? const Color(0x2EFFFFFF)),
          ),
          child: child,
        ),
      ),
    );
  }
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
    return FrostedPanel(
      padding: padding,
      borderRadius: BorderRadius.circular(22),
      color: color ?? const Color(0xC20A0A0A),
      borderColor: borderColor ?? const Color(0x2EFFFFFF),
      child: child,
    );
  }
}
