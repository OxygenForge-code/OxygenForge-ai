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

class AppSettings {
  const AppSettings({
    this.provider = AiProvider.openai,
    this.apiKeys = const <String, String>{},
    this.endpoint = '',
    this.model = '',
    this.temperature = 0.7,
    this.systemPrompt = 'You are OxygenForge AI, a concise, helpful assistant. Respond in the user\'s language.',
  });

  final AiProvider provider;
  final Map<String, String> apiKeys;
  final String endpoint;
  final String model;
  final double temperature;
  final String systemPrompt;

  String get apiKey => apiKeys[provider.name] ?? '';
  String get effectiveEndpoint => endpoint.trim().isEmpty ? provider.defaultEndpoint : endpoint.trim();
  String get effectiveModel => model.trim().isEmpty ? provider.defaultModel : model.trim();

  AppSettings copyWith({
    AiProvider? provider,
    Map<String, String>? apiKeys,
    String? endpoint,
    String? model,
    double? temperature,
    String? systemPrompt,
  }) {
    return AppSettings(
      provider: provider ?? this.provider,
      apiKeys: apiKeys ?? this.apiKeys,
      endpoint: endpoint ?? this.endpoint,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }
}
