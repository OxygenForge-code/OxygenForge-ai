import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/chat_models.dart';
import '../services/ai_service.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({required this.initial, super.key});

  final AppSettings initial;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  final _aiService = const AiService();
  late List<ApiProfile> _profiles;
  late String _selectedProfileId;
  String? _testingProfileId;

  @override
  void initState() {
    super.initState();
    _profiles = List<ApiProfile>.from(widget.initial.profiles);
    if (_profiles.isEmpty) {
      _profiles = <ApiProfile>[_newProfile(AiProvider.openai)];
    }
    _selectedProfileId = widget.initial.selectedProfileId ?? _profiles.first.id;
  }

  ApiProfile _newProfile(AiProvider provider) {
    final now = DateTime.now();
    return ApiProfile(
      id: now.microsecondsSinceEpoch.toString(),
      name: '${provider.label} profili',
      provider: provider,
      endpoint: provider.defaultEndpoint,
      model: provider.defaultModel,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _addProfile() async {
    final profile = await showModalBottomSheet<ApiProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OxygenForgeTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) =>
          ProfileEditorSheet(initial: _newProfile(AiProvider.openai)),
    );
    if (!mounted || profile == null) return;
    setState(() {
      _profiles = <ApiProfile>[..._profiles, profile];
      _selectedProfileId = profile.id;
    });
  }

  Future<void> _editProfile(ApiProfile profile) async {
    final replacement = await showModalBottomSheet<ApiProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OxygenForgeTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ProfileEditorSheet(initial: profile),
    );
    if (!mounted || replacement == null) return;
    setState(() {
      _profiles = _profiles
          .map((item) => item.id == replacement.id ? replacement : item)
          .toList();
    });
  }

  Future<void> _deleteProfile(ApiProfile profile) async {
    if (_profiles.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir API profili kalmalı.')),
      );
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${profile.name} silinsin mi?'),
        content: const Text(
          'Bu profilin anahtarı ve özel ayarları cihazdan kaldırılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: OxygenForgeTheme.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (!mounted || shouldDelete != true) return;
    setState(() {
      _profiles = _profiles.where((item) => item.id != profile.id).toList();
      if (_selectedProfileId == profile.id) {
        _selectedProfileId = _profiles.first.id;
      }
    });
  }

  Future<void> _testProfile(ApiProfile profile) async {
    setState(() => _testingProfileId = profile.id);
    try {
      await _aiService.testProfile(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${profile.name} testi başarılı.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is AiServiceException
          ? '${error.title}: ${error.message}'
          : error.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Test başarısız: $message')));
    } finally {
      if (mounted) setState(() => _testingProfileId = null);
    }
  }

  void _save() {
    Navigator.of(context).pop(
      AppSettings(
        profiles: List<ApiProfile>.unmodifiable(_profiles),
        selectedProfileId: _selectedProfileId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: OxygenForgeTheme.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'API profilleri',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'Birden fazla sağlayıcıyı ayrı profil olarak kaydet, tek dokunuşla aktif profili değiştir.',
                style: TextStyle(color: OxygenForgeTheme.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _profiles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final profile = _profiles[index];
                    final selected = profile.id == _selectedProfileId;
                    final testing = profile.id == _testingProfileId;
                    return _ProfileTile(
                      profile: profile,
                      selected: selected,
                      testing: testing,
                      onSelect: () =>
                          setState(() => _selectedProfileId = profile.id),
                      onEdit: () => _editProfile(profile),
                      onDelete: () => _deleteProfile(profile),
                      onTest: () => _testProfile(profile),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _addProfile,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni API profili ekle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: OxygenForgeTheme.text,
                  side: const BorderSide(color: OxygenForgeTheme.line),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 15,
                    color: OxygenForgeTheme.muted,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Anahtarlar yalnızca bu cihazdaki yerel depolamada saklanır. Bağlantı testi kısa bir model isteği gönderir ve sağlayıcı kotası kullanabilir.',
                      style: TextStyle(
                        color: OxygenForgeTheme.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Profilleri kaydet'),
                  style: FilledButton.styleFrom(
                    backgroundColor: OxygenForgeTheme.violet,
                    foregroundColor: Colors.black,
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

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.selected,
    required this.testing,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onTest,
  });

  final ApiProfile profile;
  final bool selected;
  final bool testing;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? OxygenForgeTheme.violetBright
        : OxygenForgeTheme.line;
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
        decoration: BoxDecoration(
          color: selected
              ? OxygenForgeTheme.violet.withValues(alpha: 0.11)
              : OxygenForgeTheme.panelRaised,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: accent),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? OxygenForgeTheme.violetBright
                  : OxygenForgeTheme.muted,
              size: 22,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.provider.label}  ·  ${profile.effectiveModel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OxygenForgeTheme.muted,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    profile.isReady ? 'Anahtar hazır' : 'API anahtarı eksik',
                    style: TextStyle(
                      color: profile.isReady
                          ? OxygenForgeTheme.green
                          : OxygenForgeTheme.error,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: OxygenForgeTheme.muted,
              ),
              color: OxygenForgeTheme.panelRaised,
              onSelected: (value) {
                switch (value) {
                  case 'test':
                    onTest();
                  case 'edit':
                    onEdit();
                  case 'delete':
                    onDelete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'test',
                  enabled: !testing,
                  child: Text(
                    testing ? 'Test ediliyor…' : 'Bağlantıyı test et',
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Profili düzenle'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Profili sil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileEditorSheet extends StatefulWidget {
  const ProfileEditorSheet({required this.initial, super.key});

  final ApiProfile initial;

  @override
  State<ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<ProfileEditorSheet> {
  late AiProvider _provider;
  late TextEditingController _nameController;
  late TextEditingController _keyController;
  late TextEditingController _endpointController;
  late TextEditingController _modelController;
  late TextEditingController _systemPromptController;
  late double _temperature;
  String? _modelValidationMessage;

  @override
  void initState() {
    super.initState();
    _provider = widget.initial.provider;
    _nameController = TextEditingController(text: widget.initial.name);
    _keyController = TextEditingController(text: widget.initial.apiKey);
    _endpointController = TextEditingController(text: widget.initial.endpoint);
    _modelController = TextEditingController(text: widget.initial.model);
    _systemPromptController = TextEditingController(
      text: widget.initial.systemPrompt,
    );
    _temperature = widget.initial.temperature;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      _endpointController.text = provider.defaultEndpoint;
      _modelController.text = provider.defaultModel;
      _modelValidationMessage = null;
      if (_nameController.text.trim().isEmpty ||
          _nameController.text == '${widget.initial.provider.label} profili') {
        _nameController.text = '${provider.label} profili';
      }
    });
  }

  void _save() {
    final model = _modelController.text.trim();
    final modelValidationMessage = _provider.modelInputError(model);
    if (modelValidationMessage != null) {
      setState(() => _modelValidationMessage = modelValidationMessage);
      return;
    }
    final name = _nameController.text.trim().isEmpty
        ? '${_provider.label} profili'
        : _nameController.text.trim();
    Navigator.of(context).pop(
      widget.initial.copyWith(
        name: name,
        provider: _provider,
        apiKey: _keyController.text.trim(),
        endpoint: _endpointController.text.trim(),
        model: model,
        temperature: _temperature,
        systemPrompt: _systemPromptController.text.trim().isEmpty
            ? AppSettings.defaultSystemPrompt
            : _systemPromptController.text.trim(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
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
                    decoration: BoxDecoration(
                      color: OxygenForgeTheme.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'API profilini düzenle',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Profil adı',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<AiProvider>(
                  initialValue: _provider,
                  decoration: const InputDecoration(
                    labelText: 'AI sağlayıcısı',
                    prefixIcon: Icon(Icons.cloud_rounded),
                  ),
                  dropdownColor: OxygenForgeTheme.panelRaised,
                  items: AiProvider.values
                      .map(
                        (provider) => DropdownMenuItem(
                          value: provider,
                          child: Text(
                            '${provider.label}  ·  ${provider.subtitle}',
                          ),
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
                    labelText: '${_provider.label} API anahtarı',
                    prefixIcon: const Icon(Icons.key_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _endpointController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'API endpoint',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _modelController,
                  onChanged: (_) {
                    if (_modelValidationMessage != null) {
                      setState(() => _modelValidationMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Model',
                    hintText: _provider.defaultModel,
                    prefixIcon: const Icon(Icons.auto_awesome_rounded),
                    errorText: _modelValidationMessage,
                  ),
                ),
                if (_provider.suggestedModels.length > 1) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Önerilen Groq modelleri',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: OxygenForgeTheme.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _provider.suggestedModels.map((model) {
                      return ChoiceChip(
                        label: Text(model),
                        selected: _modelController.text.trim() == model,
                        onSelected: (_) {
                          setState(() {
                            _modelController.text = model;
                            _modelValidationMessage = null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text(
                      'Yaratıcılık',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      _temperature.toStringAsFixed(1),
                      style: const TextStyle(
                        color: OxygenForgeTheme.violetBright,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                    prefixIcon: Icon(Icons.psychology_alt_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Profili kaydet'),
                    style: FilledButton.styleFrom(
                      backgroundColor: OxygenForgeTheme.violet,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
