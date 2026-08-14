import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_models.dart';

class AiService {
  const AiService();

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
      await Future<void>.delayed(const Duration(milliseconds: 850));
      return _demoReply(latestUserMessage.text);
    }

    final uri = Uri.tryParse(settings.endpoint);
    if (uri == null) {
      throw const FormatException('API endpoint geçerli bir URL değil.');
    }

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${settings.apiKey.trim()}',
          },
          body: jsonEncode({
            'model': settings.model.trim().isEmpty ? 'gpt-4o-mini' : settings.model.trim(),
            'temperature': 0.7,
            'messages': [
              {
                'role': 'system',
                'content': 'You are OxygenForge AI, a concise, helpful assistant. Respond in the user\'s language.',
              },
              ...history.map(
                (message) => {
                  'role': message.role == MessageRole.user ? 'user' : 'assistant',
                  'content': message.text,
                },
              ),
            ],
          }),
        )
        .timeout(const Duration(seconds: 45));

    final decoded = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded?['error'];
      final message = error is Map ? error['message'] : null;
      throw Exception(message?.toString() ?? 'API ${response.statusCode} yanıtı verdi.');
    }

    final content = decoded?['choices']?[0]?['message']?['content'];
    if (content is String && content.trim().isNotEmpty) return content.trim();
    throw const FormatException('API yanıtında mesaj içeriği bulunamadı.');
  }

  Map<String, dynamic>? _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  String _demoReply(String prompt) {
    final normalized = prompt.toLowerCase();
    if (normalized.contains('kod') || normalized.contains('flutter')) {
      return 'Demo modundayız. Flutter projen için önce hedefi küçük bir dikey dilime ayıralım: ekran akışı, veri modeli, servis katmanı ve test. API anahtarını Ayarlar\'dan eklediğinde bu yanıtlar gerçek model üzerinden üretilecek.';
    }
    if (normalized.contains('merhaba') || normalized.contains('selam')) {
      return 'Merhaba. Ben OxygenForge AI. Bir fikir, kod parçası veya çözmek istediğin problemi yaz; birlikte net bir sonraki adımı çıkaralım.';
    }
    if (normalized.contains('plan')) {
      return 'İyi bir plan için üç şeyi netleştirebiliriz: hedef çıktı, kısıtlar ve ilk doğrulanabilir adım. İstersen fikrini tek cümleyle yaz, sana uygulanabilir bir yol haritası hazırlayayım.';
    }
    return 'Bu, OxygenForge AI\'nın demo yanıtı. Gerçek bir modelle konuşmak için Ayarlar bölümünden OpenAI uyumlu API anahtarını ekleyebilirsin. İstersen sorunu bağlamı ve beklediğin çıktı ile birlikte yaz.';
  }
}
