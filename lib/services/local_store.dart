import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_models.dart';

class LocalStore {
  static const _sessionsKey = 'oxygenforge.sessions.v1';
  static const _apiKeyKey = 'oxygenforge.api_key';
  static const _endpointKey = 'oxygenforge.endpoint';
  static const _modelKey = 'oxygenforge.model';

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
    return AppSettings(
      apiKey: preferences.getString(_apiKeyKey) ?? '',
      endpoint: preferences.getString(_endpointKey) ?? 'https://api.openai.com/v1/chat/completions',
      model: preferences.getString(_modelKey) ?? 'gpt-4o-mini',
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(_apiKeyKey, settings.apiKey),
      preferences.setString(_endpointKey, settings.endpoint),
      preferences.setString(_modelKey, settings.model),
    ]);
  }
}
