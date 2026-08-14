import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../app_theme.dart';
import '../models/chat_models.dart';
import '../services/ai_service.dart';
import '../services/local_store.dart';
import '../widgets/error_card.dart';
import '../widgets/forge_logo.dart';
import '../widgets/message_bubble.dart';
import '../widgets/settings_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = LocalStore();
  final _aiService = const AiService();
  final _composerController = TextEditingController();
  final _composerFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _speech = stt.SpeechToText();

  List<ChatSession> _sessions = <ChatSession>[];
  AppSettings _settings = const AppSettings();
  String? _selectedSessionId;
  bool _isLoading = true;
  bool _isTyping = false;
  bool _isListening = false;
  AiAttachment? _attachment;
  AiServiceException? _lastError;

  ChatSession? get _selectedSession {
    for (final session in _sessions) {
      if (session.id == _selectedSessionId) return session;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

  @override
  void dispose() {
    _composerController.dispose();
    _composerFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkspace() async {
    final sessions = await _store.loadSessions();
    final settings = await _store.loadSettings();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _settings = settings;
      _selectedSessionId = sessions.isEmpty ? null : sessions.first.id;
      _isLoading = false;
    });
  }

  void _newSession() {
    final now = DateTime.now();
    final session = ChatSession(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'Yeni çalışma',
      createdAt: now,
      updatedAt: now,
    );
    setState(() {
      _sessions = [session, ..._sessions];
      _selectedSessionId = session.id;
    });
    _store.saveSessions(_sessions);
    _composerFocusNode.requestFocus();
    Navigator.of(context).maybePop();
  }

  void _selectSession(String id) {
    setState(() => _selectedSessionId = id);
    Navigator.of(context).maybePop();
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final selectedAttachment = _attachment;
    final typedPrompt = _composerController.text.trim();
    final prompt = typedPrompt.isEmpty && selectedAttachment != null ? 'Bu görseli analiz et.' : typedPrompt;
    final session = _selectedSession ?? _createAndSelectSession();
    if (prompt.isEmpty || _isTyping) return;

    setState(() {
      if (session.messages.isEmpty || session.title == 'Yeni çalışma') {
        session.title = _titleFromPrompt(prompt);
      }
      session.messages.add(
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: MessageRole.user,
          text: prompt,
          createdAt: DateTime.now(),
        ),
      );
      session.updatedAt = DateTime.now();
      _composerController.clear();
      _attachment = null;
      _isTyping = true;
    });
    await _store.saveSessions(_sessions);
    _scrollToBottom();

    try {
      final thinkingStopwatch = Stopwatch()..start();
      final response = await _aiService.reply(
        history: List<ChatMessage>.of(session.messages),
        settings: _settings,
        attachment: selectedAttachment,
      );
      thinkingStopwatch.stop();
      if (!mounted) return;
      setState(() {
       session.messages.add(
         ChatMessage(
           id: DateTime.now().microsecondsSinceEpoch.toString(),
           role: MessageRole.assistant,
           text: response.text,
           createdAt: DateTime.now(),
           provider: _settings.provider,
           model: _settings.effectiveModel,
           thinking: response.thinking,
            thinkingDuration: thinkingStopwatch.elapsed,
         ),
        );
        session.updatedAt = DateTime.now();
      });
      await _store.saveSessions(_sessions);
    } catch (error) {
      if (!mounted) return;
      setState(() => _lastError = _asAiException(error));
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
    }
  }

  ChatSession _createAndSelectSession() {
    final now = DateTime.now();
    final session = ChatSession(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'Yeni çalışma',
      createdAt: now,
      updatedAt: now,
    );
    _sessions = [session, ..._sessions];
    _selectedSessionId = session.id;
    return session;
  }

  String _titleFromPrompt(String prompt) {
    final clean = prompt.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length > 30 ? '${clean.substring(0, 30)}…' : clean;
  }

  AiServiceException _asAiException(Object error) {
    if (error is AiServiceException) return error;
    return AiServiceException(
      kind: AiFailureKind.unknown,
      provider: _settings.provider,
      message: error.toString().replaceFirst('Exception: ', '').replaceFirst('FormatException: ', ''),
    );
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openSettings() async {
    final next = await showModalBottomSheet<AppSettings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OxygenForgeTheme.panel,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SettingsSheet(initial: _settings),
    );
    if (!mounted || next == null) return;
    await _store.saveSettings(next);
    if (!mounted) return;
    setState(() => _settings = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('API profilleri kaydedildi. Aktif: ${next.activeProfile.name}')),
    );
  }

  Future<void> _clearSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: OxygenForgeTheme.panel,
        title: const Text('Geçmiş temizlensin mi?'),
        content: const Text('Tüm sohbet oturumları bu cihazdan silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: OxygenForgeTheme.error,
              foregroundColor: Colors.black,
            ),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _sessions = <ChatSession>[];
      _selectedSessionId = null;
    });
    await _store.saveSessions(_sessions);
  }

  void _usePrompt(String prompt) {
    _composerController.text = prompt;
    _composerController.selection = TextSelection.collapsed(offset: prompt.length);
    _composerFocusNode.requestFocus();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked == null) return;
    try {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _attachment = AiAttachment(
          name: picked.name,
          mimeType: picked.mimeType ?? 'image/jpeg',
          base64Data: base64Encode(bytes),
        );
      });
      _composerFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${picked.name} eklendi. İstersen bir talimat yazıp gönder.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel okunamadı: $error')),
      );
    }
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && mounted) setState(() => _isListening = false);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sesli giriş kullanılamıyor: ${error.errorMsg}')),
        );
      },
    );
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu cihazda sesli giriş kullanılamıyor veya mikrofon izni verilmedi.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isListening = true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(localeId: 'tr_TR', listenMode: stt.ListenMode.dictation),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _composerController.text = result.recognizedWords;
          _composerController.selection = TextSelection.collapsed(offset: _composerController.text.length);
        });
      },
    );
  }

  Future<void> _exportCurrentSession() async {
    final session = _selectedSession;
    if (session == null || session.messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dışa aktarmak için önce bir mesaj gönder.')),
      );
      return;
    }
    final buffer = StringBuffer('# ${session.title}\n\n');
    for (final message in session.messages) {
      final speaker = message.role == MessageRole.user ? 'Sen' : 'OxygenForge AI';
      buffer.writeln('**$speaker**');
      buffer.writeln(message.text);
      buffer.writeln();
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sohbet Markdown olarak panoya kopyalandı.')),
    );
  }

  Future<void> _regenerateLast() async {
    final session = _selectedSession;
    if (session == null || session.messages.isEmpty || _isTyping) return;
    final lastAssistantIndex = session.messages.lastIndexWhere((message) => message.role == MessageRole.assistant);
    if (lastAssistantIndex < 0) return;
    setState(() {
      session.messages.removeAt(lastAssistantIndex);
      _isTyping = true;
      _lastError = null;
    });
    await _store.saveSessions(_sessions);
    try {
      final thinkingStopwatch = Stopwatch()..start();
      final response = await _aiService.reply(
        history: List<ChatMessage>.of(session.messages),
        settings: _settings,
      );
      thinkingStopwatch.stop();
      if (!mounted) return;
      setState(() {
       session.messages.add(
         ChatMessage(
           id: DateTime.now().microsecondsSinceEpoch.toString(),
           role: MessageRole.assistant,
           text: response.text,
           createdAt: DateTime.now(),
           provider: _settings.provider,
           model: _settings.effectiveModel,
           thinking: response.thinking,
            thinkingDuration: thinkingStopwatch.elapsed,
         ),
        );
        session.updatedAt = DateTime.now();
      });
      await _store.saveSessions(_sessions);
    } catch (error) {
      if (!mounted) return;
      setState(() => _lastError = _asAiException(error));
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _retryLastPrompt() async {
    final session = _selectedSession;
    if (session == null || _isTyping) return;
    final userIndex = session.messages.lastIndexWhere((message) => message.role == MessageRole.user);
    if (userIndex < 0) return;
    final prompt = session.messages[userIndex].text;
    setState(() {
      session.messages.removeAt(userIndex);
      _lastError = null;
    });
    _composerController.text = prompt;
    _composerController.selection = TextSelection.collapsed(offset: prompt.length);
    await _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: OxygenForgeTheme.violetBright)));
    }

    final isCompact = MediaQuery.sizeOf(context).width < 980;
    return Scaffold(
      drawer: isCompact
          ? Drawer(
              backgroundColor: OxygenForgeTheme.panel,
              child: _buildSidebar(showLogo: true),
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isCompact) _buildSidebar(),
            Expanded(child: _buildWorkspace(isCompact)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar({bool showLogo = false}) {
    return Container(
      width: 278,
      decoration: const BoxDecoration(
        color: OxygenForgeTheme.panel,
        border: Border(right: BorderSide(color: OxygenForgeTheme.line)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLogo) ...[
            const ForgeLogo(),
            const SizedBox(height: 25),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _newSession,
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Yeni çalışma'),
              style: FilledButton.styleFrom(
                backgroundColor: OxygenForgeTheme.violet,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
          ),
          const SizedBox(height: 27),
          _SidebarLabel(
            label: 'ÇALIŞMA ALANI',
            trailing: IconButton(
              onPressed: _sessions.isEmpty ? null : _clearSessions,
              tooltip: 'Geçmişi temizle',
              icon: const Icon(Icons.delete_sweep_outlined, size: 17),
              color: OxygenForgeTheme.muted,
              splashRadius: 18,
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: _sessions.isEmpty
                ? const Center(
                    child: Text('Henüz sohbet yok', style: TextStyle(color: OxygenForgeTheme.muted, fontSize: 12)),
                  )
                : ListView.separated(
                    itemCount: _sessions.length,
                    padding: EdgeInsets.zero,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return _SessionTile(
                        session: session,
                        selected: session.id == _selectedSessionId,
                        onTap: () => _selectSession(session.id),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          _ConnectionCard(
            connected: _settings.apiKey.isNotEmpty,
            provider: _settings.provider,
            onTap: _openSettings,
          ),
          const SizedBox(height: 12),
          ListTile(
            onTap: _openSettings,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            leading: const Icon(Icons.tune_rounded, size: 19, color: OxygenForgeTheme.muted),
            title: const Text('Ayarlar', style: TextStyle(color: OxygenForgeTheme.muted, fontSize: 13)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: OxygenForgeTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace(bool isCompact) {
    final session = _selectedSession;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF050505), Color(0xFF000000), Color(0xFF080808)],
            ),
          ),
        ),
        IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -130,
                right: -110,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: const BoxDecoration(
                    color: Color(0x0AFFFFFF),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x18FFFFFF), blurRadius: 110, spreadRadius: 32)],
                  ),
                ),
              ),
              Positioned(
                left: -140,
                bottom: 110,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: const BoxDecoration(
                    color: Color(0x08FFFFFF),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x12FFFFFF), blurRadius: 100, spreadRadius: 24)],
                  ),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            _WorkspaceHeader(
              isCompact: isCompact,
              minimal: isCompact,
              title: session?.title ?? 'Yeni çalışma',
              profileName: _settings.activeProfile.name,
              model: _settings.effectiveModel,
              provider: _settings.provider,
              connected: _settings.apiKey.isNotEmpty,
              onSettings: _openSettings,
              onExport: _exportCurrentSession,
              onRegenerate: _regenerateLast,
            ),
            Expanded(child: _buildConversation(session, compact: isCompact)),
            _QuickActions(
              onProviders: _openSettings,
              onCamera: () => _pickImage(ImageSource.camera),
              onGallery: () => _pickImage(ImageSource.gallery),
            ),
            _Composer(
              controller: _composerController,
              focusNode: _composerFocusNode,
              isTyping: _isTyping,
              isListening: _isListening,
              attachmentName: _attachment?.name,
              onSend: _sendMessage,
              onGallery: () => _pickImage(ImageSource.gallery),
              onVoice: _toggleVoice,
              onClearAttachment: () => setState(() => _attachment = null),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConversation(ChatSession? session, {required bool compact}) {
    final messages = session?.messages ?? <ChatMessage>[];
    if (messages.isEmpty) {
      return compact ? const SizedBox.expand() : _WelcomeView(onPromptTap: _usePrompt);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 18),
      itemCount: messages.length + (_isTyping ? 1 : 0) + (_lastError != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == messages.length) {
          return const Padding(
            padding: EdgeInsets.only(left: 0, bottom: 22),
            child: TypingBubble(),
          );
        }
        if (_lastError != null && index == messages.length + (_isTyping ? 1 : 0)) {
          return ErrorCard(
            exception: _lastError!,
            onRetry: _retryLastPrompt,
            onSettings: _openSettings,
          );
        }
        return MessageBubble(key: ValueKey(messages[index].id), message: messages[index]);
      },
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.isCompact,
    required this.minimal,
    required this.title,
    required this.profileName,
    required this.model,
    required this.provider,
    required this.connected,
    required this.onSettings,
    required this.onExport,
    required this.onRegenerate,
  });

  final bool isCompact;
  final bool minimal;
  final String title;
  final String profileName;
  final String model;
  final AiProvider provider;
  final bool connected;
  final VoidCallback onSettings;
  final VoidCallback onExport;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    if (minimal) {
      return _MinimalHeader(profileName: profileName, onSettings: onSettings);
    }
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: OxygenForgeTheme.ink,
        border: Border(bottom: BorderSide(color: OxygenForgeTheme.line)),
      ),
      child: Row(
        children: [
          if (isCompact) ...[
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menüyü aç',
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    title,
                    key: ValueKey(title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 13, color: connected ? OxygenForgeTheme.green : OxygenForgeTheme.violetBright),
                    const SizedBox(width: 5),
                    AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                      child: Text(
                        connected ? '${provider.label}  ·  $model' : '${provider.label} demo motoru',
                        key: ValueKey('${provider.name}-$model-$connected'),
                        style: const TextStyle(color: OxygenForgeTheme.muted, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ModePill(label: connected ? 'Anahtar hazır' : 'Demo mod', connected: connected),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onRegenerate,
            tooltip: 'Son yanıtı yeniden üret',
            icon: const Icon(Icons.refresh_rounded, color: OxygenForgeTheme.muted),
          ),
          IconButton(
            onPressed: onExport,
            tooltip: 'Sohbeti kopyala',
            icon: const Icon(Icons.ios_share_rounded, color: OxygenForgeTheme.muted),
          ),
          IconButton(
            onPressed: onSettings,
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.tune_rounded, color: OxygenForgeTheme.muted),
          ),
        ],
      ),
    );
  }
}

class _MinimalHeader extends StatelessWidget {
  const _MinimalHeader({required this.profileName, required this.onSettings});

  final String profileName;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(
          children: [
            Builder(
              builder: (context) => IconButton.filledTonal(
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: 'Menüyü aç',
                style: IconButton.styleFrom(
                  backgroundColor: OxygenForgeTheme.panelRaised,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: OxygenForgeTheme.line),
                  padding: const EdgeInsets.all(14),
                ),
                icon: const Icon(Icons.menu_rounded, size: 23),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onSettings,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  color: OxygenForgeTheme.panelRaised,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: OxygenForgeTheme.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        profileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.expand_more_rounded, color: OxygenForgeTheme.muted, size: 18),
                  ],
                ),
              ),
            ),
            const Spacer(),
            IconButton.filledTonal(
              onPressed: onSettings,
              tooltip: 'Bağlantılar',
              style: IconButton.styleFrom(
                backgroundColor: OxygenForgeTheme.panelRaised,
                foregroundColor: Colors.white,
                side: const BorderSide(color: OxygenForgeTheme.line),
                padding: const EdgeInsets.all(14),
              ),
              icon: const Icon(Icons.blur_circular_rounded, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.onPromptTap});

  final ValueChanged<String> onPromptTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 46, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 790),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const ForgeGradient(),
                  boxShadow: const [BoxShadow(color: Color(0x33FFFFFF), blurRadius: 30, offset: Offset(0, 10))],
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 32),
              ),
              const SizedBox(height: 25),
              ShaderMask(
                shaderCallback: (bounds) => const ForgeGradient().createShader(bounds),
                child: const Text(
                  'Fikrini ateşle.',
                  style: TextStyle(color: Colors.white, fontSize: 37, fontWeight: FontWeight.w800, letterSpacing: -1.2),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'OxygenForge AI, fikirlerini netleştirmek ve üretime taşımak için sessiz, odaklı bir çalışma alanı.',
                style: TextStyle(color: OxygenForgeTheme.muted, fontSize: 15, height: 1.55),
              ),
              const SizedBox(height: 34),
              const Text('Nereden başlamak istersin?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _PromptCard(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Bir fikri geliştir',
                    subtitle: 'Konseptini uygulanabilir adımlara çevir',
                    prompt: 'Bu fikri daha net ve uygulanabilir hale getirmeme yardım et: ',
                    onTap: onPromptTap,
                  ),
                  _PromptCard(
                    icon: Icons.code_rounded,
                    title: 'Kod yaz veya düzelt',
                    subtitle: 'Bir problemi birlikte analiz et',
                    prompt: 'Şu kod problemini analiz et ve çözüm öner: ',
                    onTap: onPromptTap,
                  ),
                  _PromptCard(
                    icon: Icons.map_outlined,
                    title: 'Bir plan oluştur',
                    subtitle: 'Hedefine giden yolu sadeleştir',
                    prompt: 'Şu hedef için adım adım bir plan oluştur: ',
                    onTap: onPromptTap,
                  ),
                  _PromptCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Metni iyileştir',
                    subtitle: 'Yazını daha güçlü ve net yap',
                    prompt: 'Şu metni daha profesyonel ve net hale getir: ',
                    onTap: onPromptTap,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const _PrivacyNote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.prompt,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String prompt;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(prompt),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 370,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: OxygenForgeTheme.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: OxygenForgeTheme.line),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: OxygenForgeTheme.violet.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: OxygenForgeTheme.violetBright, size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: OxygenForgeTheme.muted, fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_outward_rounded, size: 16, color: OxygenForgeTheme.muted),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_outline_rounded, size: 15, color: OxygenForgeTheme.muted),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Sohbet geçmişin bu cihazda saklanır. API anahtarı eklemeden demo modunu deneyebilirsin.',
            style: const TextStyle(color: OxygenForgeTheme.muted, fontSize: 11.5),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onProviders, required this.onCamera, required this.onGallery});

  final VoidCallback onProviders;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        children: [
          _QuickActionChip(icon: Icons.hub_rounded, label: 'Try Connectors', onPressed: onProviders),
          const SizedBox(width: 8),
          _QuickActionChip(icon: Icons.camera_alt_rounded, label: 'Open Camera', onPressed: onCamera),
          const SizedBox(width: 8),
          _QuickActionChip(icon: Icons.photo_library_rounded, label: 'Choose Image', onPressed: onGallery),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatefulWidget {
  const _QuickActionChip({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip> with SingleTickerProviderStateMixin {
  late final AnimationController _attentionController;
  var _pressed = false;

  @override
  void initState() {
    super.initState();
    _attentionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1350));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _attentionController.stop();
    } else if (_attentionController.status == AnimationStatus.dismissed) {
      _attentionController.forward();
    }
  }

  @override
  void dispose() {
    _attentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _attentionController,
      builder: (context, child) {
        final lift = reduceMotion ? 0.0 : -1.5 * _attentionController.value;
        return Transform.translate(offset: Offset(0, lift), child: child);
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: ActionChip(
            onPressed: widget.onPressed,
            avatar: Icon(widget.icon, size: 17, color: OxygenForgeTheme.text),
            label: Text(widget.label),
            labelStyle: const TextStyle(color: OxygenForgeTheme.text, fontSize: 12.5, fontWeight: FontWeight.w600),
            backgroundColor: const Color(0x1CFFFFFF),
            side: const BorderSide(color: Color(0x36FFFFFF)),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.isTyping,
    required this.isListening,
    required this.attachmentName,
    required this.onSend,
    required this.onGallery,
    required this.onVoice,
    required this.onClearAttachment,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isTyping;
  final bool isListening;
  final String? attachmentName;
  final VoidCallback onSend;
  final VoidCallback onGallery;
  final VoidCallback onVoice;
  final VoidCallback onClearAttachment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: const Color(0xB0111111),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isListening ? OxygenForgeTheme.violetBright : const Color(0x36FFFFFF)),
            boxShadow: [
              BoxShadow(
                color: isListening ? OxygenForgeTheme.text.withValues(alpha: 0.16) : const Color(0x40000000),
                blurRadius: isListening ? 34 : 24,
                spreadRadius: isListening ? 1 : 0,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (attachmentName != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 4),
                    child: InputChip(
                      avatar: const Icon(Icons.image_rounded, size: 16, color: OxygenForgeTheme.violetBright),
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(attachmentName!, overflow: TextOverflow.ellipsis),
                      ),
                      onDeleted: onClearAttachment,
                      deleteIconColor: OxygenForgeTheme.muted,
                      backgroundColor: OxygenForgeTheme.violet.withValues(alpha: 0.12),
                      side: BorderSide.none,
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: isTyping ? null : onGallery,
                    tooltip: 'Görsel ekle',
                    icon: const Icon(Icons.add_rounded, size: 26, color: OxygenForgeTheme.text),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => onSend(),
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        filled: false,
                        hintText: 'Ask OxygenForge AI…',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isTyping ? null : onVoice,
                    tooltip: isListening ? 'Dinlemeyi durdur' : 'Sesli giriş',
                    icon: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
                      child: Icon(
                        isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        key: ValueKey(isListening),
                        color: isListening ? OxygenForgeTheme.violetBright : OxygenForgeTheme.muted,
                      ),
                    ),
                  ),
                  AnimatedScale(
                    scale: isTyping ? 0.9 : 1,
                    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: IconButton.filled(
                      onPressed: isTyping ? null : onSend,
                      tooltip: 'Gönder',
                      style: IconButton.styleFrom(
                        backgroundColor: OxygenForgeTheme.violet,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: OxygenForgeTheme.line,
                        disabledForegroundColor: OxygenForgeTheme.muted,
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: AnimatedSwitcher(
                        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) => RotationTransition(turns: animation, child: FadeTransition(opacity: animation, child: child)),
                        child: Icon(
                          isTyping ? Icons.hourglass_top_rounded : Icons.arrow_upward_rounded,
                          key: ValueKey(isTyping),
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel({required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: OxygenForgeTheme.muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2))),
        ?trailing,
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.selected, required this.onTap});

  final ChatSession session;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: selected ? 1 : 0.985,
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? OxygenForgeTheme.violet.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? OxygenForgeTheme.text.withValues(alpha: 0.18) : Colors.transparent,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          leading: AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
            child: Icon(
              selected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
              key: ValueKey(selected),
              size: 17,
              color: selected ? OxygenForgeTheme.violetBright : OxygenForgeTheme.muted,
            ),
          ),
          title: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: selected ? OxygenForgeTheme.text : OxygenForgeTheme.muted, fontSize: 12.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
          ),
          subtitle: Text(_relativeDate(session.updatedAt), style: const TextStyle(color: OxygenForgeTheme.muted, fontSize: 10.5)),
        ),
      ),
    );
  }

  String _relativeDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'şimdi';
    if (difference.inMinutes < 60) return '${difference.inMinutes} dk önce';
    if (difference.inHours < 24) return '${difference.inHours} sa önce';
    return '${difference.inDays} gün önce';
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.connected, required this.provider, required this.onTap});

  final bool connected;
  final AiProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = connected ? OxygenForgeTheme.green : OxygenForgeTheme.cyan;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: connected
              ? [BoxShadow(color: OxygenForgeTheme.text.withValues(alpha: 0.08), blurRadius: 18, spreadRadius: 1)]
              : const [],
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => RotationTransition(turns: animation, child: FadeTransition(opacity: animation, child: child)),
              child: Icon(
                connected ? Icons.check_circle_outline_rounded : Icons.bolt_rounded,
                key: ValueKey(connected),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(connected ? '${provider.label} hazır' : '${provider.label} demo', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(connected ? 'Anahtar kaydedildi' : 'Anahtar eklemek için aç', style: const TextStyle(color: OxygenForgeTheme.muted, fontSize: 10.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: OxygenForgeTheme.muted, size: 18),
          ],
        ),
      ),
    );
  }
}
