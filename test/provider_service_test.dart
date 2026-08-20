import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:oxygenforge_ai/models/chat_models.dart';
import 'package:oxygenforge_ai/services/ai_service.dart';

void main() {
  final history = <ChatMessage>[
    ChatMessage(
      id: 'user-1',
      role: MessageRole.user,
      text: 'Merhaba',
      createdAt: DateTime(2026),
    ),
  ];

  test(
    'OpenAI uyumlu sağlayıcılar ortak chat completions sözleşmesini kullanır',
    () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.groq.com/openai/v1/chat/completions',
        );
        expect(request.headers['authorization'], 'Bearer groq-test-key');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'llama-test');
        expect((body['messages'] as List).length, 2);
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Groq yanıtı'},
                },
              ],
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await AiService(client: client).reply(
        history: history,
        settings: const AppSettings(
          provider: AiProvider.groq,
          apiKeys: {'groq': 'groq-test-key'},
          endpoint: 'https://api.groq.com/openai/v1/chat/completions',
          model: 'llama-test',
        ),
      );

      expect(result.text, 'Groq yanıtı');
      expect(result.thinking, isNull);
    },
  );

  test(
    'Gemini native generateContent request ve response alanlarını eşler',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/v1beta/models/gemini-test:generateContent');
        expect(request.url.queryParameters['key'], 'gemini-test-key');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['contents'], isA<List<dynamic>>());
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Gemini yanıtı'},
                    ],
                  },
                },
              ],
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final result = await AiService(client: client).reply(
        history: history,
        settings: const AppSettings(
          provider: AiProvider.gemini,
          apiKeys: {'gemini': 'gemini-test-key'},
          endpoint: 'https://generativelanguage.googleapis.com/v1beta',
          model: 'gemini-test',
        ),
      );

      expect(result.text, 'Gemini yanıtı');
      expect(result.thinking, isNull);
    },
  );

  test('Anthropic Messages API response içindeki text bloğunu okur', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/messages');
      expect(request.headers['x-api-key'], 'claude-test-key');
      expect(request.headers['anthropic-version'], '2023-06-01');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'content': [
              {'type': 'text', 'text': 'Claude yanıtı'},
            ],
          }),
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final result = await AiService(client: client).reply(
      history: history,
      settings: const AppSettings(
        provider: AiProvider.anthropic,
        apiKeys: {'anthropic': 'claude-test-key'},
        endpoint: 'https://api.anthropic.com/v1/messages',
        model: 'claude-test',
      ),
    );

    expect(result.text, 'Claude yanıtı');
    expect(result.thinking, isNull);
  });

  test('think ve analysis bloklarını görünür yanıttan ayırıp düşünme alanında saklar', () async {
    final client = MockClient((_) async {
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '<think>Gizli iç adımlar.</think>\n<analysis>Gizli analiz.</analysis>\n\n**Güvenli yanıt**',
                },
              },
            ],
          }),
        ),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final result = await AiService(client: client).reply(
      history: history,
      settings: const AppSettings(
        provider: AiProvider.groq,
        apiKeys: {'groq': 'groq-test-key'},
        endpoint: 'https://api.groq.com/openai/v1/chat/completions',
        model: 'llama-test',
      ),
    );

    expect(result.text, '**Güvenli yanıt**');
    expect(result.text, isNot(contains('<think>')));
    expect(result.text, isNot(contains('<analysis>')));
    expect(result.thinking, 'Gizli iç adımlar.\n\nGizli analiz.');
  });

  test('Model erişim hatasını kullanıcı kurtarma akışı için ayırır', () async {
    final client = MockClient((_) async {
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'error': {
              'message': "The model 'llama-3.0-legacy' does not exist or you do not have access to it.",
            },
          }),
        ),
        400,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    expect(
      () => AiService(client: client).reply(
        history: history,
        settings: const AppSettings(
          provider: AiProvider.groq,
          apiKeys: {'groq': 'groq-test-key'},
          endpoint: 'https://api.groq.com/openai/v1/chat/completions',
          model: 'llama-3.0-legacy',
        ),
      ),
      throwsA(
        isA<AiServiceException>()
            .having((error) => error.kind, 'kind', AiFailureKind.modelNotFound)
            .having((error) => error.title, 'title', 'Model kullanılamıyor'),
      ),
    );
  });

  test(
    'DNS/socket hatası kullanıcıya network failure olarak taşınır',
    () async {
      final client = MockClient((_) async {
        throw http.ClientException("Failed host lookup: 'api.groq.com'");
      });

      expect(
        () => AiService(client: client).reply(
          history: history,
          settings: const AppSettings(
            provider: AiProvider.groq,
            apiKeys: {'groq': 'groq-test-key'},
            endpoint: 'https://api.groq.com/openai/v1/chat/completions',
          ),
        ),
        throwsA(
          isA<AiServiceException>()
              .having((error) => error.kind, 'kind', AiFailureKind.network)
              .having((error) => error.title, 'title', 'Bağlantı kurulamadı'),
        ),
      );
    },
  );
}
