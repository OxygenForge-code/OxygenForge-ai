import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_models.dart';

enum AiFailureKind {
  network,
  authentication,
  rateLimit,
  invalidRequest,
  server,
  decoding,
  unknown,
}

class AiServiceException implements Exception {
  const AiServiceException({
    required this.kind,
    required this.provider,
    required this.message,
    this.statusCode,
  });

  final AiFailureKind kind;
  final AiProvider provider;
  final String message;
  final int? statusCode;

  String get title {
    switch (kind) {
      case AiFailureKind.network:
        return 'Bağlantı kurulamadı';
      case AiFailureKind.authentication:
        return 'API anahtarı kontrol edilmeli';
      case AiFailureKind.rateLimit:
        return 'Kullanım limiti aşıldı';
      case AiFailureKind.invalidRequest:
        return 'İstek kabul edilmedi';
      case AiFailureKind.server:
        return 'Sağlayıcı geçici olarak yanıt vermiyor';
      case AiFailureKind.decoding:
        return 'Yanıt okunamadı';
      case AiFailureKind.unknown:
        return 'Beklenmeyen bağlantı hatası';
    }
  }

  String get recoveryTip {
    switch (kind) {
      case AiFailureKind.network:
        return 'İnternet bağlantını ve DNS erişimini kontrol et. Endpoint’i Ayarlar’dan doğrulayabilir veya tekrar deneyebilirsin.';
      case AiFailureKind.authentication:
        return 'Seçili sağlayıcı için API anahtarının doğru ve aktif olduğundan emin ol.';
      case AiFailureKind.rateLimit:
        return 'Biraz bekleyip tekrar dene veya başka bir sağlayıcı/model seç.';
      case AiFailureKind.invalidRequest:
        return 'Model adını, endpoint’i ve sağlayıcının desteklediği parametreleri kontrol et.';
      case AiFailureKind.server:
        return 'Sağlayıcı durumunu kontrol et veya geçici olarak başka bir sağlayıcıya geç.';
      case AiFailureKind.decoding:
        return 'Model ve endpoint’in seçili sağlayıcıyla uyumlu olduğundan emin ol.';
      case AiFailureKind.unknown:
        return 'Ayarları kontrol edip tekrar dene.';
    }
  }

  @override
  String toString() => '$title: $message';
}

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

  Future<http.Response> _post({
    required Uri uri,
    required Map<String, String> headers,
    required Object body,
    required AppSettings settings,
  }) async {
    try {
      return await _httpClient
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      throw AiServiceException(
        kind: AiFailureKind.network,
        provider: settings.provider,
        message: 'İstek 45 saniye içinde tamamlanmadı.',
      );
    } on http.ClientException catch (error) {
      throw AiServiceException(
        kind: AiFailureKind.network,
        provider: settings.provider,
        message: _networkMessage(error.message),
      );
    } catch (error) {
      final text = error.toString();
      if (text.contains('SocketFailed') || text.contains('Failed host lookup') || text.contains('No address associated')) {
        throw AiServiceException(
          kind: AiFailureKind.network,
          provider: settings.provider,
          message: _networkMessage(text),
        );
      }
      rethrow;
    }
  }

  String _networkMessage(String raw) {
    final clean = raw.replaceFirst('ClientException: ', '').trim();
    if (clean.contains('Failed host lookup') || clean.contains('No address associated')) {
      return 'Alan adı çözümlenemedi. Cihazın DNS veya internet bağlantısı api endpoint’ine erişemiyor.';
    }
    return clean.length > 180 ? '${clean.substring(0, 180)}…' : clean;
  }

  Future<String> _replyWithOpenAiCompatible({
    required List<ChatMessage> history,
    required AppSettings settings,
  }) async {
    final uri = _parseUri(settings.effectiveEndpoint, settings);
    final response = await _post(
      uri: uri,
      settings: settings,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${settings.apiKey.trim()}',
        if (settings.provider == AiProvider.openRouter) ...{
          'HTTP-Referer': 'https://github.com/OxygenForge-code/OxygenForge-ai',
          'X-Title': 'OxygenForge AI',
        },
      },
      body: {
        'model': settings.effectiveModel,
        'temperature': settings.temperature,
        'messages': [
          {'role': 'system', 'content': settings.systemPrompt},
          ..._compatibleMessages(history),
        ],
      },
    );

    final decoded = _decodeResponse(response.body, settings);
    _throwIfFailed(response, decoded, settings);
    final content = decoded?['choices']?[0]?['message']?['content'];
    if (content is String && content.trim().isNotEmpty) return content.trim();
    throw AiServiceException(
      kind: AiFailureKind.decoding,
      provider: settings.provider,
      message: 'choices[0].message.content alanı bulunamadı.',
    );
  }

  Future<String> _replyWithGemini({
    required List<ChatMessage> history,
    required AppSettings settings,
  }) async {
    final endpoint = settings.effectiveEndpoint.endsWith('/')
        ? settings.effectiveEndpoint.substring(0, settings.effectiveEndpoint.length - 1)
        : settings.effectiveEndpoint;
    final uri = _parseUri(
      '$endpoint/models/${settings.effectiveModel}:generateContent?key=${Uri.encodeQueryComponent(settings.apiKey.trim())}',
      settings,
    );

    final response = await _post(
      uri: uri,
      settings: settings,
      headers: const {'Content-Type': 'application/json'},
      body: {
        'systemInstruction': {
          'parts': [
            {'text': settings.systemPrompt},
          ],
        },
        'contents': history
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
      },
    );

    final decoded = _decodeResponse(response.body, settings);
    _throwIfFailed(response, decoded, settings);
    final candidates = decoded?['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final firstCandidate = candidates.first;
      final content = firstCandidate is Map ? firstCandidate['content'] : null;
      final parts = content is Map ? content['parts'] : null;
      if (parts is List) {
        final text = parts.whereType<Map>().map((part) => part['text']).whereType<String>().join();
        if (text.trim().isNotEmpty) return text.trim();
      }
    }
    throw AiServiceException(
      kind: AiFailureKind.decoding,
      provider: settings.provider,
      message: 'candidates[0].content.parts alanı bulunamadı.',
    );
  }

  Future<String> _replyWithAnthropic({
    required List<ChatMessage> history,
    required AppSettings settings,
  }) async {
    final response = await _post(
      uri: _parseUri(settings.effectiveEndpoint, settings),
      settings: settings,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': settings.apiKey.trim(),
        'anthropic-version': '2023-06-01',
      },
      body: {
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
      },
    );

    final decoded = _decodeResponse(response.body, settings);
    _throwIfFailed(response, decoded, settings);
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
    throw AiServiceException(
      kind: AiFailureKind.decoding,
      provider: settings.provider,
      message: 'content içindeki text bloğu bulunamadı.',
    );
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

  Uri _parseUri(String endpoint, AppSettings settings) {
    final uri = Uri.tryParse(endpoint);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw AiServiceException(
        kind: AiFailureKind.invalidRequest,
        provider: settings.provider,
        message: 'Endpoint geçerli bir URL değil: $endpoint',
      );
    }
    return uri;
  }

  Map<String, dynamic>? _decodeResponse(String body, AppSettings settings) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      throw AiServiceException(
        kind: AiFailureKind.decoding,
        provider: settings.provider,
        message: 'Sağlayıcı geçerli JSON döndürmedi.',
      );
    }
  }

  void _throwIfFailed(http.Response response, Map<String, dynamic>? decoded, AppSettings settings) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final error = decoded?['error'];
    final message = error is Map ? error['message'] : null;
    final kind = switch (response.statusCode) {
      401 || 403 => AiFailureKind.authentication,
      429 => AiFailureKind.rateLimit,
      >= 500 => AiFailureKind.server,
      400 || 404 || 422 => AiFailureKind.invalidRequest,
      _ => AiFailureKind.unknown,
    };
    throw AiServiceException(
      kind: kind,
      provider: settings.provider,
      statusCode: response.statusCode,
      message: message?.toString() ?? 'HTTP ${response.statusCode} yanıtı alındı.',
    );
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
