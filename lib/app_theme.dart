import 'package:flutter/material.dart';

class OxygenForgeTheme {
  static const ink = Colors.black;
  static const panel = Color(0xFF121212);
  static const panelRaised = Color(0xFF1D1D20);
  static const line = Color(0xFF35353A);
  static const referenceSurface = Color(0xFF1A1A1D);
  static const referenceSurfacePressed = Color(0xFF2A2A2F);
  static const referenceBlue = Color(0xFF3A7BFF);
  static const referenceBlueBright = Color(0xFF6DA4FF);
  static const referenceBlueSoft = Color(0x263A7BFF);
  static const referenceDeep = Color(0xFF09090B);
  static const referenceHighlight = Color(0x1FFFFFFF);
  static const surfaceGlow = Color(0x1F3A7BFF);
  static const surfaceStroke = Color(0x3AFFFFFF);
  static const glass = Color(0xC90B0B0B);
  static const glassSoft = Color(0x9C121212);
  static const glassEdge = Color(0x42FFFFFF);
  static const glassEdgeSoft = Color(0x24FFFFFF);
  static const softShadow = Color(0x7A000000);
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
        color: referenceSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: surfaceStroke),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: referenceSurface,
        hintStyle: const TextStyle(color: muted),
        labelStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: surfaceStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: surfaceStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: referenceBlueBright, width: 1.4),
        ),
      ),
      dividerColor: line,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: referenceSurfacePressed,
        contentTextStyle: const TextStyle(color: text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: referenceDeep,
        indicatorColor: referenceBlueSoft,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: referenceDeep,
        modalBackgroundColor: referenceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: color == null
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF202024), OxygenForgeTheme.referenceSurface],
              )
            : null,
        color: color,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? OxygenForgeTheme.surfaceStroke,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
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
