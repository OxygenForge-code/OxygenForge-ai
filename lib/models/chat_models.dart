enum MessageRole { user, assistant }

enum AiProvider {
  openai,
  gemini,
  groq,
  openRouter,
  anthropic,
  mistral,
  together,
  deepSeek,
  custom,
}

extension AiProviderLabel on AiProvider {
  String get label {
    switch (this) {
      case AiProvider.openai:
        return 'OpenAI';
      case AiProvider.gemini:
        return 'Gemini';
      case AiProvider.groq:
        return 'Groq';
      case AiProvider.openRouter:
        return 'OpenRouter';
      case AiProvider.anthropic:
        return 'Anthropic';
      case AiProvider.mistral:
        return 'Mistral';
      case AiProvider.together:
        return 'Together AI';
      case AiProvider.deepSeek:
        return 'DeepSeek';
      case AiProvider.custom:
        return 'Custom API';
    }
  }

  String get subtitle {
    switch (this) {
      case AiProvider.openai:
        return 'GPT modelleri';
      case AiProvider.gemini:
        return 'Google modelleri';
      case AiProvider.groq:
        return 'Hızlı inference';
      case AiProvider.openRouter:
        return 'Yüzlerce model';
      case AiProvider.anthropic:
        return 'Claude modelleri';
      case AiProvider.mistral:
        return 'Mistral modelleri';
      case AiProvider.together:
        return 'Açık modeller';
      case AiProvider.deepSeek:
        return 'DeepSeek modelleri';
      case AiProvider.custom:
        return 'OpenAI uyumlu';
    }
  }

  String get defaultModel {
    switch (this) {
      case AiProvider.openai:
        return 'gpt-4o-mini';
      case AiProvider.gemini:
        return 'gemini-2.5-flash';
      case AiProvider.groq:
        return 'llama-3.3-70b-versatile';
      case AiProvider.openRouter:
        return 'openai/gpt-4o-mini';
      case AiProvider.anthropic:
        return 'claude-3-5-haiku-latest';
      case AiProvider.mistral:
        return 'mistral-small-latest';
      case AiProvider.together:
        return 'meta-llama/Llama-3.3-70B-Instruct-Turbo';
      case AiProvider.deepSeek:
        return 'deepseek-chat';
      case AiProvider.custom:
        return 'your-model';
    }
  }

  String get defaultEndpoint {
    switch (this) {
      case AiProvider.openai:
        return 'https://api.openai.com/v1/chat/completions';
      case AiProvider.gemini:
        return 'https://generativelanguage.googleapis.com/v1beta';
      case AiProvider.groq:
        return 'https://api.groq.com/openai/v1/chat/completions';
      case AiProvider.openRouter:
        return 'https://openrouter.ai/api/v1/chat/completions';
      case AiProvider.anthropic:
        return 'https://api.anthropic.com/v1/messages';
      case AiProvider.mistral:
        return 'https://api.mistral.ai/v1/chat/completions';
      case AiProvider.together:
        return 'https://api.together.xyz/v1/chat/completions';
      case AiProvider.deepSeek:
        return 'https://api.deepseek.com/chat/completions';
      case AiProvider.custom:
        return 'https://your-endpoint.example/v1/chat/completions';
    }
  }

  bool get isOpenAiCompatible =>
      this != AiProvider.gemini && this != AiProvider.anthropic;

  bool supportsVisionModel(String model) {
    final normalized = model.toLowerCase();
    switch (this) {
      case AiProvider.gemini:
      case AiProvider.anthropic:
        return true;
      case AiProvider.openai:
        return normalized.contains('gpt-4o') || normalized.contains('gpt-4.1') || normalized.contains('vision');
      case AiProvider.groq:
        return normalized.contains('vision') || normalized.contains('llama-4');
      case AiProvider.openRouter:
      case AiProvider.mistral:
      case AiProvider.together:
      case AiProvider.deepSeek:
      case AiProvider.custom:
        return normalized.contains('vision') || normalized.contains('image') || normalized.contains('llama-4');
    }
  }

}

AiProvider aiProviderFromName(String? name) {
  return AiProvider.values.firstWhere(
    (provider) => provider.name == name,
    orElse: () => AiProvider.openai,
  );
}

class AiAttachment {
  const AiAttachment({required this.name, required this.mimeType, required this.base64Data});

  final String name;
  final String mimeType;
  final String base64Data;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.provider,
    this.model,
  });

  final String id;
  final MessageRole role;
  final String text;
  final DateTime createdAt;
  final AiProvider? provider;
  final String? model;

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'provider': provider?.name,
        'model': model,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      role: (json['role'] as String?) == MessageRole.user.name
          ? MessageRole.user
          : MessageRole.assistant,
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      provider: json['provider'] is String ? aiProviderFromName(json['provider'] as String) : null,
      model: json['model'] as String?,
    );
  }
}

class ChatSession {
  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    List<ChatMessage>? messages,
  }) : messages = messages ?? <ChatMessage>[];

  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<ChatMessage> messages;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((message) => message.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    return ChatSession(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? 'Yeni çalışma',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      messages: rawMessages is List
          ? rawMessages
              .whereType<Map>()
              .map((message) => ChatMessage.fromJson(Map<String, dynamic>.from(message)))
              .toList()
          : <ChatMessage>[],
    );
  }
}

class ApiProfile {
  const ApiProfile({
    required this.id,
    required this.name,
    required this.provider,
    this.apiKey = '',
    this.endpoint = '',
    this.model = '',
    this.temperature = 0.7,
    this.systemPrompt = AppSettings.defaultSystemPrompt,
    required this.createdAt,
    required this.updatedAt,
  });

  ApiProfile.legacy({
    required AiProvider provider,
    required Map<String, String> apiKeys,
    required this.endpoint,
    required this.model,
    required this.temperature,
    required this.systemPrompt,
  })  : id = 'legacy',
        name = 'Varsayılan ${provider.label}',
        provider = provider,
        apiKey = apiKeys[provider.name] ?? '',
        createdAt = DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  final String id;
  final String name;
  final AiProvider provider;
  final String apiKey;
  final String endpoint;
  final String model;
  final double temperature;
  final String systemPrompt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get effectiveEndpoint => endpoint.trim().isEmpty ? provider.defaultEndpoint : endpoint.trim();
  String get effectiveModel => model.trim().isEmpty ? provider.defaultModel : model.trim();
  bool get isReady => apiKey.trim().isNotEmpty;

  ApiProfile copyWith({
    String? name,
    AiProvider? provider,
    String? apiKey,
    String? endpoint,
    String? model,
    double? temperature,
    String? systemPrompt,
    DateTime? updatedAt,
  }) {
    return ApiProfile(
      id: id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      endpoint: endpoint ?? this.endpoint,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider.name,
        'apiKey': apiKey,
        'endpoint': endpoint,
        'model': model,
        'temperature': temperature,
        'systemPrompt': systemPrompt,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ApiProfile.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final provider = aiProviderFromName(json['provider'] as String?);
    return ApiProfile(
      id: json['id'] as String? ?? now.microsecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? provider.label,
      provider: provider,
      apiKey: json['apiKey'] as String? ?? '',
      endpoint: json['endpoint'] as String? ?? '',
      model: json['model'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      systemPrompt: json['systemPrompt'] as String? ?? AppSettings.defaultSystemPrompt,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
    );
  }
}

class AppSettings {
  const AppSettings({
    AiProvider provider = AiProvider.openai,
    Map<String, String> apiKeys = const <String, String>{},
    String endpoint = '',
    String model = '',
    double temperature = 0.7,
    String systemPrompt = defaultSystemPrompt,
    this.profiles = const <ApiProfile>[],
    this.selectedProfileId,
  })  : _legacyProvider = provider,
        _legacyApiKeys = apiKeys,
        _legacyEndpoint = endpoint,
        _legacyModel = model,
        _legacyTemperature = temperature,
        _legacySystemPrompt = systemPrompt;

  static const defaultSystemPrompt = 'You are OxygenForge AI, a concise, helpful assistant. Respond in the user\'s language.';

  final AiProvider _legacyProvider;
  final Map<String, String> _legacyApiKeys;
  final String _legacyEndpoint;
  final String _legacyModel;
  final double _legacyTemperature;
  final String _legacySystemPrompt;

  final List<ApiProfile> profiles;
  final String? selectedProfileId;

  bool get hasProfiles => profiles.isNotEmpty;

  ApiProfile get activeProfile {
    for (final profile in profiles) {
      if (profile.id == selectedProfileId) return profile;
    }
    if (profiles.isNotEmpty) return profiles.first;
    return ApiProfile.legacy(
      provider: _legacyProvider,
      apiKeys: _legacyApiKeys,
      endpoint: _legacyEndpoint,
      model: _legacyModel,
      temperature: _legacyTemperature,
      systemPrompt: _legacySystemPrompt,
    );
  }

  AiProvider get provider => activeProfile.provider;
  Map<String, String> get apiKeys => hasProfiles
      ? {for (final profile in profiles) profile.id: profile.apiKey}
      : _legacyApiKeys;
  String get apiKey => activeProfile.apiKey;
  String get endpoint => activeProfile.endpoint;
  String get model => activeProfile.model;
  double get temperature => activeProfile.temperature;
  String get systemPrompt => activeProfile.systemPrompt;
  String get effectiveEndpoint => activeProfile.effectiveEndpoint;
  String get effectiveModel => activeProfile.effectiveModel;
  bool get supportsVision => provider.supportsVisionModel(effectiveModel);

  AppSettings copyWith({
    AiProvider? provider,
    Map<String, String>? apiKeys,
    String? endpoint,
    String? model,
    double? temperature,
    String? systemPrompt,
    List<ApiProfile>? profiles,
    String? selectedProfileId,
  }) {
    return AppSettings(
      provider: provider ?? _legacyProvider,
      apiKeys: apiKeys ?? _legacyApiKeys,
      endpoint: endpoint ?? _legacyEndpoint,
      model: model ?? _legacyModel,
      temperature: temperature ?? _legacyTemperature,
      systemPrompt: systemPrompt ?? _legacySystemPrompt,
      profiles: profiles ?? this.profiles,
      selectedProfileId: selectedProfileId ?? this.selectedProfileId,
    );
  }

  AppSettings withProfiles(List<ApiProfile> nextProfiles, {String? activeProfileId}) {
    return AppSettings(
      profiles: List<ApiProfile>.unmodifiable(nextProfiles),
      selectedProfileId: activeProfileId ?? selectedProfileId,
    );
  }
}
