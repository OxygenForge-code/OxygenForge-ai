import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_models.dart';

class AiService {
  const AiService({this._client});

  final http.Client? _client;

  http.Client get _httpClient => _client ?? http.Client();

  Future<String> reply({
    required List<ChatMessage> history,
    required AppSettings settings,
  }) async {
    final latestUserMessage = history.lastWhere(
      (message) => message.role == MessageRole.user,
      orElse: () => ChatMessage(
        id: 'empty',
        role: MessageRole.user,
        text: 'Merhaba',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );

    if (settings.apiKey.trim().isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      return _demoReply(latestUserMessage.text, settings.provider);
    }

    switch (settings.provider) {
      case AiProvider.gemini:
        return _replyWithGemini(history: history, settings: settings);
      case AiProvider.anthropic:
        return _replyWithAnthropic(history: history, settings: settings);
      case AiProvider.openai:
      case AiProvider.groq:
      case AiProvider.openRouter:
      case AiProvider.mistral:
      case AiProvider.together:
      case AiProvider.deepSeek:
      case AiProvider.custom:
        return _replyWithOpenAiCompatible(history: history, settings: settings);
    }
  }

  Future<String> _replyWithOpenAiCompatible({
    required List<ChatMessage> history,
    required AppSettings settings,
  }) async {
    final uri = _parseUri(settings.effectiveEndpoint);
    final response = await _httpClient
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${settings.apiKey.trim()}',
            if (settings.provider == AiProvider.openRouter) ...{
              'HTTP-Referer': 'https://github.com/OxygenForge-code/OxygenForge-ai',
              'X-Title': 'OxygenForge AI',
            },
          },
          body: jsonEncode({
            'model': settings.effectiveModel,
            'temperature': settings.temperature,
            'messages': [
              {'role': 'system', 'content': settings.systemPrompt},
              ..._compatibleMessages(history),
            ],
          }),
        )
        .timeout(const Duration(seconds: 45));

    final decoded = _decodeResponse(response.body);
    _throwIfFailed(response, decoded);
    final content = decoded?['choices']?[0]?['message']?['content'];
    if (content is String && content.trim().isNotEmpty) return content.trim();
    throw const FormatException('Sağlayıcı yanıtında mesaj içeriği bulunamadı.');
  }

  Future<String> _replyWithGemini({
    required List<ChatMessage> history,
    required AppSettings settings,
  }) async {
    final endpoint = settings.effectiveEndpoint.endsWith('/')
        ? settings.effectiveEndpoint.substring(0, settings.effectiveEndpoint.length - 1)
        : settings.effectiveEndpoint;
    final uri = Uri.tryParse('$endpoint/models/${settings.effectiveModel}:generateContent?key=${Uri.encodeQueryComponent(settings.apiKey.trim())}');
    if (uri == null) throw const FormatException('Gemini endpoint geçerli bir URL değil.');

    final response = await _httpClient
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'systemInstruction': {
              'parts': [
                {'text': settings.systemPrompt},
              ],
            },
            'contents': history
                .where((message) => message.role != MessageRole.assistant || message.text.trim().isNotEmpty)
                .map(
                  (message) => {
                    'role': message.role == MessageRole.user ? 'user' : 'model',
                    'parts': [
                      {'text': message.text},
                    ],
                  },
                )
                .toList(),
            'generationConfig': {'temperature': settings.temperature},
          }),
        )
        .timeout(const Duration(seconds: 45));

    final decoded = _decodeResponse(response.body);
    _throwIfFailed(response, decoded);
    final candidates = decoded?['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final firstCandidate = candidates.first;
      final content = firstCandidate is Map ? firstCandidate['content'] : null;
      final parts = content is Map ? content['parts'] : null;
      if (parts is List) {
        final text = parts
            .whereType<Map>()
            .map((part) => part['text'])
            .whereType<String>()
            .join();
        if (text.trim().isNotEmpty) return text.trim();
      }
    }
    throw const FormatException('Gemini yanıtında metin içeriği bulunamadı.');
  }

  Future<String> _replyWithAnthropic({
    required List<ChatMessage> history,
    required AppSettings settings,
  }) async {
    final response = await _httpClient
        .post(
          _parseUri(settings.effectiveEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': settings.apiKey.trim(),
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode({
            'model': settings.effectiveModel,
            'max_tokens': 2048,
            'temperature': settings.temperature,
            'system': settings.systemPrompt,
            'messages': history
                .map(
                  (message) => {
                    'role': message.role == MessageRole.user ? 'user' : 'assistant',
                    'content': message.text,
                  },
                )
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 45));

    final decoded = _decodeResponse(response.body);
    _throwIfFailed(response, decoded);
    final content = decoded?['content'];
    if (content is List) {
      final text = content
          .whereType<Map>()
          .where((block) => block['type'] == 'text')
          .map((block) => block['text'])
          .whereType<String>()
          .join();
      if (text.trim().isNotEmpty) return text.trim();
    }
    throw const FormatException('Anthropic yanıtında metin içeriği bulunamadı.');
  }

  List<Map<String, String>> _compatibleMessages(List<ChatMessage> history) {
    return history
        .map(
          (message) => {
            'role': message.role == MessageRole.user ? 'user' : 'assistant',
            'content': message.text,
          },
        )
        .toList();
  }

  Uri _parseUri(String endpoint) {
    final uri = Uri.tryParse(endpoint);
    if (uri == null || !uri.hasScheme) {
      throw const FormatException('API endpoint geçerli bir URL değil.');
    }
    return uri;
  }

  Map<String, dynamic>? _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  void _throwIfFailed(http.Response response, Map<String, dynamic>? decoded) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final error = decoded?['error'];
    final message = error is Map ? error['message'] : null;
    throw Exception(message?.toString() ?? 'Sağlayıcı ${response.statusCode} yanıtı verdi.');
  }

  String _demoReply(String prompt, AiProvider provider) {
    final normalized = prompt.toLowerCase();
    if (normalized.contains('kod') || normalized.contains('flutter')) {
      return '${provider.label} demo modundayız. Flutter projen için hedefi küçük bir dikey dilime ayıralım: ekran akışı, veri modeli, servis katmanı ve test. Gerçek yanıtlar için bu sağlayıcının API anahtarını Ayarlar\'dan ekleyebilirsin.';
    }
    if (normalized.contains('merhaba') || normalized.contains('selam')) {
      return 'Merhaba. Ben OxygenForge AI. Şu an ${provider.label} demo motoru aktif. Bir fikir, kod parçası veya çözmek istediğin problemi yaz; birlikte net bir sonraki adımı çıkaralım.';
    }
    if (normalized.contains('plan')) {
      return 'İyi bir plan için üç şeyi netleştirebiliriz: hedef çıktı, kısıtlar ve ilk doğrulanabilir adım. İstersen fikrini tek cümleyle yaz, sana uygulanabilir bir yol haritası hazırlayayım.';
    }
    return '${provider.label} demo yanıtı hazır. Gerçek bir modelle konuşmak için Ayarlar bölümünden sağlayıcı anahtarını ekleyebilirsin. İstersen sorunu bağlamı ve beklediğin çıktı ile birlikte yaz.';
  }
}
