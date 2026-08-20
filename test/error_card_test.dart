import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oxygenforge_ai/models/chat_models.dart';
import 'package:oxygenforge_ai/services/ai_service.dart';
import 'package:oxygenforge_ai/widgets/error_card.dart';

void main() {
  testWidgets(
    'Model erişim hatası önerilen model ve profil düzenleme aksiyonlarını gösterir',
    (WidgetTester tester) async {
      var usedRecommendedModel = false;
      var openedSettings = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorCard(
              exception: const AiServiceException(
                kind: AiFailureKind.modelNotFound,
                provider: AiProvider.groq,
                message: 'Seçili model bu API anahtarı için kullanılamıyor.',
              ),
              onRetry: () {},
              onSettings: () => openedSettings = true,
              onUseRecommendedModel: () => usedRecommendedModel = true,
            ),
          ),
        ),
      );

      expect(find.text('Model kullanılamıyor'), findsOneWidget);
      expect(find.text('llama-3.1-8b-instant modelini kullan'), findsOneWidget);
      expect(find.text('Profili düzenle'), findsOneWidget);

      await tester.tap(find.text('llama-3.1-8b-instant modelini kullan'));
      await tester.pump();
      expect(usedRecommendedModel, isTrue);

      await tester.tap(find.text('Profili düzenle'));
      await tester.pump();
      expect(openedSettings, isTrue);
    },
  );
}
