import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oxygenforge_ai/app_theme.dart';
import 'package:oxygenforge_ai/models/chat_models.dart';
import 'package:oxygenforge_ai/widgets/message_bubble.dart';

void main() {
  test('Düşünme metni sohbet mesajı JSON kaydında korunur', () {
    final message = ChatMessage(
      id: 'assistant-1',
      role: MessageRole.assistant,
      text: '**Sonuç**',
      thinking: 'Önce verileri değerlendirdim.',
      thinkingDuration: const Duration(milliseconds: 850),
      createdAt: DateTime(2026, 8, 14),
      provider: AiProvider.groq,
      model: 'deepseek-r1-distill-llama-70b',
    );

    final restored = ChatMessage.fromJson(message.toJson());

    expect(restored.text, '**Sonuç**');
    expect(restored.thinking, 'Önce verileri değerlendirdim.');
    expect(restored.thinkingDuration, const Duration(milliseconds: 850));
  });

  testWidgets('Asistan mesajı düşünme metnini varsayılan olarak gösterir ve kapatabilir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OxygenForgeTheme.build(),
        home: Scaffold(
          body: MessageBubble(
            message: ChatMessage(
              id: 'assistant-2',
              role: MessageRole.assistant,
              text: '**Yanıt**',
              thinking: '1. Bağlamı inceledim.\n2. Uygun sonucu oluşturdum.',
              thinkingDuration: const Duration(milliseconds: 1350),
              createdAt: DateTime(2026, 8, 14),
              provider: AiProvider.groq,
              model: 'deepseek-r1-distill-llama-70b',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Modelin düşünme süreci'), findsOneWidget);
    expect(find.text('1.4 sn düşündü'), findsOneWidget);
    expect(find.byType(FrostedPanel), findsWidgets);
    expect(find.textContaining('Bağlamı inceledim.'), findsOneWidget);

    await tester.tap(find.text('Modelin düşünme süreci'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Bağlamı inceledim.'), findsNothing);
  });
}
