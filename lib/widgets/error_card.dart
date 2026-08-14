import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/ai_service.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({
    required this.exception,
    required this.onRetry,
    required this.onSettings,
    super.key,
  });

  final AiServiceException exception;
  final VoidCallback onRetry;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        color: OxygenForgeTheme.error.withValues(alpha: 0.06),
        borderColor: OxygenForgeTheme.error.withValues(alpha: 0.25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: OxygenForgeTheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.error_outline_rounded, color: OxygenForgeTheme.error, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    exception.title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: OxygenForgeTheme.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              exception.message,
              style: const TextStyle(fontSize: 13.5, height: 1.45, color: OxygenForgeTheme.text),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, size: 16, color: OxygenForgeTheme.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      exception.recoveryTip,
                      style: const TextStyle(fontSize: 12, color: OxygenForgeTheme.muted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSettings,
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text('Ayarları kontrol et'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: OxygenForgeTheme.text,
                      side: const BorderSide(color: OxygenForgeTheme.line),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Tekrar dene'),
                    style: FilledButton.styleFrom(
                      backgroundColor: OxygenForgeTheme.error.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
