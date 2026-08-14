import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_models.dart';

class LocalStore {
  static const _sessionsKey = 'oxygenforge.sessions.v1';
  static const _settingsKey = 'oxygenforge.settings.v3';
  static const _previousSettingsKey = 'oxygenforge.settings.v2';
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
    final encoded = preferences.getString(_settingsKey) ?? preferences.getString(_previousSettingsKey);
    if (encoded != null && encoded.isNotEmpty) {
      try {
        final decoded = jsonDecode(encoded);
        if (decoded is Map) {
          final json = Map<String, dynamic>.from(decoded);
          final rawProfiles = json['profiles'];
          if (rawProfiles is List) {
            final profiles = rawProfiles
                .whereType<Map>()
                .map((profile) => ApiProfile.fromJson(Map<String, dynamic>.from(profile)))
                .toList();
            return AppSettings(
              profiles: profiles,
              selectedProfileId: json['selectedProfileId'] as String?,
            );
          }
          return _migrateSingleSettings(json);
        }
      } catch (_) {
        // Fall through to legacy preferences migration.
      }
    }

    final legacyKey = preferences.getString(_legacyApiKey) ?? '';
    final legacyEndpoint = preferences.getString(_legacyEndpoint) ?? '';
    final legacyModel = preferences.getString(_legacyModel) ?? '';
    final now = DateTime.now();
    final profile = ApiProfile(
      id: 'legacy-openai',
      name: 'Varsayılan OpenAI',
      provider: AiProvider.openai,
      apiKey: legacyKey,
      endpoint: legacyEndpoint,
      model: legacyModel,
      createdAt: now,
      updatedAt: now,
    );
    return AppSettings(profiles: <ApiProfile>[profile], selectedProfileId: profile.id);
  }

  AppSettings _migrateSingleSettings(Map<String, dynamic> json) {
    final now = DateTime.now();
    final activeProvider = aiProviderFromName(json['provider'] as String?);
    final rawKeys = json['apiKeys'];
    final keys = rawKeys is Map
        ? rawKeys.map((key, value) => MapEntry(key.toString(), value.toString()))
        : <String, String>{};
    final providers = <AiProvider>{activeProvider};
    for (final key in keys.keys) {
      providers.add(aiProviderFromName(key));
    }
    final profiles = providers.map((provider) {
      final isActive = provider == activeProvider;
      return ApiProfile(
        id: 'migrated-${provider.name}',
        name: 'Varsayılan ${provider.label}',
        provider: provider,
        apiKey: keys[provider.name] ?? '',
        endpoint: isActive ? json['endpoint'] as String? ?? '' : '',
        model: isActive ? json['model'] as String? ?? '' : '',
        temperature: isActive ? (json['temperature'] as num?)?.toDouble() ?? 0.7 : 0.7,
        systemPrompt: isActive
            ? json['systemPrompt'] as String? ?? AppSettings.defaultSystemPrompt
            : AppSettings.defaultSystemPrompt,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
    final active = profiles.firstWhere((profile) => profile.provider == activeProvider);
    return AppSettings(profiles: profiles, selectedProfileId: active.id);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _settingsKey,
      jsonEncode({
        'profiles': settings.profiles.map((profile) => profile.toJson()).toList(),
        'selectedProfileId': settings.selectedProfileId,
      }),
    );
  }
}
