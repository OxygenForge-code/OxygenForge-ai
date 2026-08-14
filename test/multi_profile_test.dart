import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oxygenforge_ai/models/chat_models.dart';
import 'package:oxygenforge_ai/services/local_store.dart';

void main() {
  ApiProfile profile({
    required String id,
    required String name,
    required AiProvider provider,
    required String apiKey,
  }) {
    final now = DateTime(2026, 8, 14);
    return ApiProfile(
      id: id,
      name: name,
      provider: provider,
      apiKey: apiKey,
      endpoint: provider.defaultEndpoint,
      model: provider.defaultModel,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('seçili profil aktif sağlayıcı, model ve anahtarı belirler', () {
    final openAi = profile(id: 'openai', name: 'OpenAI çalışma', provider: AiProvider.openai, apiKey: 'openai-key');
    final groq = profile(id: 'groq', name: 'Groq hızlı', provider: AiProvider.groq, apiKey: 'groq-key');
    final settings = AppSettings(profiles: <ApiProfile>[openAi, groq], selectedProfileId: groq.id);

    expect(settings.activeProfile.name, 'Groq hızlı');
    expect(settings.provider, AiProvider.groq);
    expect(settings.apiKey, 'groq-key');
    expect(settings.effectiveModel, AiProvider.groq.defaultModel);
  });

  test('birden fazla profil cihazda kaydedilip yeniden yüklenir', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = LocalStore();
    final gemini = profile(id: 'gemini', name: 'Gemini görsel', provider: AiProvider.gemini, apiKey: 'gemini-key');
    final anthropic = profile(id: 'anthropic', name: 'Claude yazı', provider: AiProvider.anthropic, apiKey: 'anthropic-key');

    await store.saveSettings(AppSettings(profiles: <ApiProfile>[gemini, anthropic], selectedProfileId: anthropic.id));
    final restored = await store.loadSettings();

    expect(restored.profiles, hasLength(2));
    expect(restored.selectedProfileId, anthropic.id);
    expect(restored.activeProfile.provider, AiProvider.anthropic);
    expect(restored.activeProfile.apiKey, 'anthropic-key');
  });

  test('v2 tek sağlayıcılı ayarlar ayrı profil listesine migrate edilir', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'oxygenforge.settings.v2': jsonEncode(<String, Object>{
        'provider': 'groq',
        'apiKeys': <String, String>{'groq': 'groq-key', 'gemini': 'gemini-key'},
        'endpoint': 'https://api.groq.com/openai/v1/chat/completions',
        'model': 'llama-3.3-70b-versatile',
        'temperature': 0.3,
        'systemPrompt': 'Kısa yanıt ver.',
      }),
    });

    final restored = await LocalStore().loadSettings();

    expect(restored.profiles, hasLength(2));
    expect(restored.activeProfile.provider, AiProvider.groq);
    expect(restored.activeProfile.apiKey, 'groq-key');
    expect(restored.profiles.where((item) => item.provider == AiProvider.gemini).single.apiKey, 'gemini-key');
  });
}
