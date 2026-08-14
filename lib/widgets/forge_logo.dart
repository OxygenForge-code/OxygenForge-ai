import 'package:flutter/material.dart';

import '../app_theme.dart';

class ForgeLogo extends StatelessWidget {
  const ForgeLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 30.0 : 38.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 10 : 13),
            gradient: const ForgeGradient(),
            boxShadow: const [
              BoxShadow(color: Color(0x40FFFFFF), blurRadius: 18, offset: Offset(0, 6)),
            ],
          ),
          child: Icon(Icons.bolt_rounded, size: compact ? 19 : 23, color: Colors.black),
        ),
        if (!compact) ...[
          const SizedBox(width: 12),
          const Text(
            'OXYGENFORGE',
            style: TextStyle(
              color: OxygenForgeTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.1,
            ),
          ),
        ],
      ],
    );
  }
}

class ModePill extends StatelessWidget {
  const ModePill({required this.label, required this.connected, super.key});

  final String label;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? OxygenForgeTheme.green : OxygenForgeTheme.violetBright;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
