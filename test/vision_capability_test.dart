import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:oxygenforge_ai/models/chat_models.dart';
import 'package:oxygenforge_ai/services/ai_service.dart';

void main() {
  AppSettings settingsFor(String model) {
    final now = DateTime(2026, 8, 14);
    final profile = ApiProfile(
      id: 'groq',
      name: 'Groq test',
      provider: AiProvider.groq,
      apiKey: 'test-key',
      endpoint: AiProvider.groq.defaultEndpoint,
      model: model,
      createdAt: now,
      updatedAt: now,
    );
    return AppSettings(profiles: <ApiProfile>[profile], selectedProfileId: profile.id);
  }

  final history = <ChatMessage>[
    ChatMessage(id: 'user', role: MessageRole.user, text: 'Bu görseli açıkla.', createdAt: DateTime(2026, 8, 14)),
  ];
  const attachment = AiAttachment(name: 'moon.jpg', mimeType: 'image/jpeg', base64Data: 'aGVsbG8=');

  test('Groq metin modeli görsel isteğini ağ çağrısından önce engeller', () async {
    var requested = false;
    final service = AiService(
      client: MockClient((_) async {
        requested = true;
        return http.Response('{}', 200);
      }),
    );

    expect(
      () => service.reply(history: history, settings: settingsFor('llama-3.3-70b-versatile'), attachment: attachment),
      throwsA(
        isA<AiServiceException>().having((error) => error.kind, 'kind', AiFailureKind.visionUnsupported),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(requested, isFalse);
  });

  test('Groq vision modeli görseli OpenAI uyumlu çok parçalı content olarak gönderir', () async {
    Map<String, dynamic>? payload;
    final service = AiService(
      client: MockClient((request) async {
        payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'Görsel işlendi.'},
              }
            ],
          }),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final reply = await service.reply(
      history: history,
      settings: settingsFor('llama-3.2-11b-vision-preview'),
      attachment: attachment,
    );

    final messages = payload!['messages'] as List<dynamic>;
    final content = (messages.last as Map<String, dynamic>)['content'];
    expect(reply.text, 'Görsel işlendi.');
    expect(content, isA<List<dynamic>>());
    expect((content as List<dynamic>).last['type'], 'image_url');
  });
}
