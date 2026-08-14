import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_models.dart';

class LocalStore {
  static const _sessionsKey = 'oxygenforge.sessions.v1';
  static const _settingsKey = 'oxygenforge.settings.v2';
  static const _legacyApiKey = 'oxygenforge.api_key';
  static const _legacyEndpoint = 'oxygenforge.endpoint';
  static const _legacyModel = 'oxygenforge.model';

  Future<List<ChatSession>> loadSessions() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_sessionsKey);
    if (encoded == null || encoded.isEmpty) return <ChatSession>[];

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return <ChatSession>[];
      return decoded
          .whereType<Map>()
          .map((session) => ChatSession.fromJson(Map<String, dynamic>.from(session)))
          .toList();
    } catch (_) {
      return <ChatSession>[];
    }
  }

  Future<void> saveSessions(List<ChatSession> sessions) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _sessionsKey,
      jsonEncode(sessions.map((session) => session.toJson()).toList()),
    );
  }

  Future<AppSettings> loadSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_settingsKey);
    if (encoded != null && encoded.isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map) {
          final json = Map<String, dynamic>.from(decoded);
          final rawKeys = json['apiKeys'];
          return AppSettings(
            provider: aiProviderFromName(json['provider'] as String?),
            apiKeys: rawKeys is Map
                ? rawKeys.map((key, value) => MapEntry(key.toString(), value.toString()))
                : <String, String>{},
            endpoint: json['endpoint'] as String? ?? '',
            model: json['model'] as String? ?? '',
            temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
            systemPrompt: json['systemPrompt'] as String? ?? AppSettings().systemPrompt,
          );
        }
      } catch (_) {
        // Fall through to the legacy migration below.
      }
    }

    final legacyKey = preferences.getString(_legacyApiKey) ?? '';
    final legacyEndpoint = preferences.getString(_legacyEndpoint) ?? '';
    final legacyModel = preferences.getString(_legacyModel) ?? '';
    return AppSettings(
      apiKeys: legacyKey.isEmpty ? <String, String>{} : <String, String>{AiProvider.openai.name: legacyKey},
      endpoint: legacyEndpoint,
      model: legacyModel,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _settingsKey,
      jsonEncode({
        'provider': settings.provider.name,
        'apiKeys': settings.apiKeys,
        'endpoint': settings.endpoint,
        'model': settings.model,
        'temperature': settings.temperature,
        'systemPrompt': settings.systemPrompt,
      }),
    );
  }
}
