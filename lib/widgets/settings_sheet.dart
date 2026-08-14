import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/chat_models.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({required this.initial, super.key});

  final AppSettings initial;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late AiProvider _provider;
  late TextEditingController _keyController;
  late TextEditingController _endpointController;
  late TextEditingController _modelController;
  late TextEditingController _systemPromptController;
  late double _temperature;

  @override
  void initState() {
    super.initState();
    _provider = widget.initial.provider;
    _keyController = TextEditingController(text: widget.initial.apiKey);
    _endpointController = TextEditingController(text: widget.initial.endpoint);
    _modelController = TextEditingController(text: widget.initial.model);
    _systemPromptController = TextEditingController(text: widget.initial.systemPrompt);
    _temperature = widget.initial.temperature;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  void _changeProvider(AiProvider? provider) {
    if (provider == null || provider == _provider) return;
    setState(() {
      _provider = provider;
      final previousKey = widget.initial.apiKeys[provider.name] ?? '';
      _keyController.text = previousKey;
      _endpointController.text = provider.defaultEndpoint;
      _modelController.text = provider.defaultModel;
    });
  }

  void _save() {
    final apiKeys = Map<String, String>.from(widget.initial.apiKeys);
    apiKeys[_provider.name] = _keyController.text.trim();
    Navigator.of(context).pop(
      widget.initial.copyWith(
        provider: _provider,
        apiKeys: apiKeys,
        endpoint: _endpointController.text.trim(),
        model: _modelController.text.trim(),
        temperature: _temperature,
        systemPrompt: _systemPromptController.text.trim().isEmpty
            ? AppSettings().systemPrompt
            : _systemPromptController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 14, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(color: OxygenForgeTheme.line, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: OxygenForgeTheme.violet.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.hub_rounded, color: OxygenForgeTheme.violetBright),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI bağlantıları', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Sağlayıcını seç, anahtarını ekle, modeli değiştir.', style: TextStyle(color: OxygenForgeTheme.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              DropdownButtonFormField<AiProvider>(
                initialValue: provider,
                decoration: const InputDecoration(labelText: 'AI sağlayıcısı', prefixIcon: Icon(Icons.cloud_rounded)),
                dropdownColor: OxygenForgeTheme.panelRaised,
                items: AiProvider.values
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text('${option.label}  ·  ${option.subtitle}'),
                      ),
                    )
                    .toList(),
                onChanged: _changeProvider,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _keyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '${provider.label} API anahtarı',
                  hintText: 'Anahtarı buraya yapıştır',
                  prefixIcon: const Icon(Icons.key_rounded),
                  suffixIcon: _keyController.text.isEmpty
                      ? null
                      : const Icon(Icons.check_circle_rounded, color: OxygenForgeTheme.green),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _endpointController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: provider == AiProvider.gemini ? 'Gemini API base URL' : 'API endpoint',
                  prefixIcon: const Icon(Icons.link_rounded),
                  helperText: provider.isOpenAiCompatible
                      ? 'OpenAI uyumlu chat completions sözleşmesi kullanılır.'
                      : provider == AiProvider.gemini
                          ? 'Gemini generateContent endpoint’i otomatik tamamlanır.'
                          : 'Sağlayıcıya özel Messages API sözleşmesi kullanılır.',
                  helperStyle: const TextStyle(color: OxygenForgeTheme.muted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: 'Model',
                  hintText: provider.defaultModel,
                  prefixIcon: const Icon(Icons.auto_awesome_rounded),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 18, color: OxygenForgeTheme.muted),
                  const SizedBox(width: 9),
                  const Text('Yaratıcılık', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  Text(_temperature.toStringAsFixed(1), style: const TextStyle(color: OxygenForgeTheme.violetBright, fontWeight: FontWeight.w700)),
                ],
              ),
              Slider(
                value: _temperature,
                min: 0,
                max: 1.5,
                divisions: 15,
                activeColor: OxygenForgeTheme.violetBright,
                onChanged: (value) => setState(() => _temperature = value),
              ),
              TextField(
                controller: _systemPromptController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Sistem promptu',
                  hintText: 'Asistanın nasıl davranacağını yaz…',
                  prefixIcon: Icon(Icons.psychology_alt_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 15, color: OxygenForgeTheme.muted),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Anahtarlar yalnızca bu cihazdaki yerel depolamada tutulur. Üretimde güvenli backend kullanılması önerilir.',
                      style: TextStyle(color: OxygenForgeTheme.muted, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Bağlantıyı kaydet'),
                  style: FilledButton.styleFrom(
                    backgroundColor: OxygenForgeTheme.violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
