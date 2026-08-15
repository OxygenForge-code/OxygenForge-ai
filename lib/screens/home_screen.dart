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
  final _sessionSearchController = TextEditingController();
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
  String _sessionQuery = '';

  ChatSession? get _selectedSession {
    for (final session in _sessions) {
      if (session.id == _selectedSessionId) return session;
    }
    return null;
  }

  List<ChatSession> get _visibleSessions {
    final query = _sessionQuery.trim().toLowerCase();
    final visible = _sessions.where((session) {
      if (query.isEmpty) return true;
      if (session.title.toLowerCase().contains(query)) return true;
      return session.messages.any(
        (message) => message.text.toLowerCase().contains(query),
      );
    }).toList();
    visible.sort((left, right) {
      if (left.isPinned != right.isPinned) return left.isPinned ? -1 : 1;
      return right.updatedAt.compareTo(left.updatedAt);
    });
    return visible;
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
    _sessionSearchController.dispose();
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

  void _updateSessionQuery(String query) {
    setState(() => _sessionQuery = query);
  }

  Future<void> _renameSession(ChatSession session) async {
    final controller = TextEditingController(text: session.title);
    final nextTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: OxygenForgeTheme.panel,
        title: const Text('Çalışmayı yeniden adlandır'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 64,
          decoration: const InputDecoration(hintText: 'Çalışma adı'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    final normalized = nextTitle?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    if (normalized.isEmpty || !mounted) return;
    setState(() {
      session.title = normalized;
      session.updatedAt = DateTime.now();
    });
    await _store.saveSessions(_sessions);
  }

  Future<void> _toggleSessionPin(ChatSession session) async {
    setState(() {
      session.isPinned = !session.isPinned;
      session.updatedAt = DateTime.now();
    });
    await _store.saveSessions(_sessions);
  }

  Future<void> _deleteSession(ChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: OxygenForgeTheme.panel,
        title: const Text('Çalışma silinsin mi?'),
        content: Text(
          '“${session.title}” ve içindeki mesajlar bu cihazdan kaldırılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _sessions.removeWhere((item) => item.id == session.id);
      if (_selectedSessionId == session.id) {
        _selectedSessionId = _visibleSessions.isEmpty
            ? null
            : _visibleSessions.first.id;
      }
    });
    await _store.saveSessions(_sessions);
  }

  Future<void> _showSessionActions(ChatSession session) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: OxygenForgeTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: OxygenForgeTheme.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                title: Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline_rounded),
                title: const Text('Yeniden adlandır'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _renameSession(session);
                },
              ),
              ListTile(
                leading: Icon(
                  session.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                ),
                title: Text(
                  session.isPinned ? 'Sabitlemeyi kaldır' : 'Sabitle',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _toggleSessionPin(session);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Çalışmayı sil'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _deleteSession(session);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openWorkspaceBoard() async {
    final session = _selectedSession;
    if (session == null) {
      _newSession();
      return;
    }
    final notesController = TextEditingController(text: session.notes);
    final taskController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OxygenForgeTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final completed = session.tasks
              .where((task) => task.isCompleted)
              .length;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                12,
                18,
                18 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
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
                    const SizedBox(height: 18),
                    const Text(
                      'ÇALIŞMA PANOSU',
                      style: TextStyle(
                        color: OxygenForgeTheme.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'NOTLAR',
                      style: TextStyle(
                        color: OxygenForgeTheme.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Bu çalışma için kısa notlarını yaz...',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'GÖREVLER',
                          style: TextStyle(
                            color: OxygenForgeTheme.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$completed/${session.tasks.length} tamamlandı',
                          style: const TextStyle(
                            color: OxygenForgeTheme.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    if (session.tasks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Henüz görev yok. Son yanıttan görev çıkarabilir veya aşağıdan ekleyebilirsin.',
                          style: TextStyle(
                            color: OxygenForgeTheme.muted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      )
                    else
                      ...session.tasks.map(
                        (task) => CheckboxListTile(
                          value: task.isCompleted,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? OxygenForgeTheme.muted
                                  : OxygenForgeTheme.text,
                              fontSize: 13,
                            ),
                          ),
                          secondary: IconButton(
                            onPressed: () {
                              setState(() {
                                session.tasks.remove(task);
                                session.updatedAt = DateTime.now();
                              });
                              _store.saveSessions(_sessions);
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.close_rounded, size: 17),
                            tooltip: 'Görevi sil',
                          ),
                          onChanged: (value) {
                            setState(() {
                              task.isCompleted = value ?? false;
                              session.updatedAt = DateTime.now();
                            });
                            _store.saveSessions(_sessions);
                            setSheetState(() {});
                          },
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: taskController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: 'Yeni görev ekle',
                            ),
                            onSubmitted: (_) => _addBoardTask(
                              session,
                              taskController,
                              setSheetState,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () => _addBoardTask(
                            session,
                            taskController,
                            setSheetState,
                          ),
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'Görev ekle',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Text(
                          'İÇGÖRÜ KASASI',
                          style: TextStyle(
                            color: OxygenForgeTheme.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${session.insights.length} kayıt',
                          style: const TextStyle(
                            color: OxygenForgeTheme.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (session.insights.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Son AI yanıtını komut merkezinden içgörü olarak kaydedebilirsin.',
                          style: TextStyle(
                            color: OxygenForgeTheme.muted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      )
                    else
                      ...session.insights.reversed.map(
                        (insight) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                          decoration: BoxDecoration(
                            color: const Color(0x16000000),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x24FFFFFF)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.bookmark_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  insight.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    session.insights.remove(insight);
                                    session.updatedAt = DateTime.now();
                                  });
                                  _store.saveSessions(_sessions);
                                  setSheetState(() {});
                                },
                                icon: const Icon(Icons.close_rounded, size: 17),
                                tooltip: 'İçgörüyü sil',
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final notes = notesController.text.trim();
                          setState(() {
                            session.notes = notes;
                            session.updatedAt = DateTime.now();
                          });
                          await _store.saveSessions(_sessions);
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Notları kaydet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    notesController.dispose();
    taskController.dispose();
  }

  void _addBoardTask(
    ChatSession session,
    TextEditingController controller,
    StateSetter setSheetState,
  ) {
    final title = controller.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (title.isEmpty) return;
    setState(() {
      session.tasks.add(
        WorkspaceTask(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title,
          createdAt: DateTime.now(),
        ),
      );
      session.updatedAt = DateTime.now();
    });
    controller.clear();
    _store.saveSessions(_sessions);
    setSheetState(() {});
  }

  Future<void> _extractTasksFromLastAnswer() async {
    final session = _selectedSession;
    if (session == null) return;
    final assistantIndex = session.messages.lastIndexWhere(
      (message) => message.role == MessageRole.assistant,
    );
    if (assistantIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce AI’dan bir yanıt al.')),
      );
      return;
    }
    final source = session.messages[assistantIndex];
    final candidateLines = source.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) {
          return RegExp(r'^(?:[-*•]|\d+[.)])\s+').hasMatch(line) ||
              RegExp(r'^\[[ xX]\]\s+').hasMatch(line);
        });
    final existing = session.tasks
        .map((task) => task.title.toLowerCase())
        .toSet();
    final extracted = <String>[];
    for (final line in candidateLines) {
      final title = line
          .replaceFirst(RegExp(r'^(?:[-*•]|\d+[.)])\s*(?:\[[ xX]\]\s*)?'), '')
          .trim();
      if (title.length < 3 ||
          existing.contains(title.toLowerCase()) ||
          extracted.any((item) => item.toLowerCase() == title.toLowerCase())) {
        continue;
      }
      extracted.add(title);
      if (extracted.length == 8) break;
    }
    if (extracted.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Son yanıtta görev olarak çıkarılacak madde bulunamadı.',
          ),
        ),
      );
      return;
    }
    setState(() {
      for (final title in extracted) {
        session.tasks.add(
          WorkspaceTask(
            id: '${DateTime.now().microsecondsSinceEpoch}-${session.tasks.length}',
            title: title,
            createdAt: DateTime.now(),
            sourceMessageId: source.id,
          ),
        );
      }
      session.updatedAt = DateTime.now();
    });
    await _store.saveSessions(_sessions);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${extracted.length} görev çalışma panosuna eklendi.'),
      ),
    );
  }

  Future<void> _saveLastAnswerAsInsight() async {
    final session = _selectedSession;
    if (session == null) return;
    final index = session.messages.lastIndexWhere(
      (message) => message.role == MessageRole.assistant,
    );
    if (index < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydetmek için önce bir AI yanıtı al.')),
      );
      return;
    }
    final source = session.messages[index];
    if (session.insights.any(
      (insight) => insight.sourceMessageId == source.id,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Son yanıt zaten içgörü kasasına kaydedildi.'),
        ),
      );
      return;
    }
    final plain = source.text
        .replaceAll(RegExp(r'[#*_`>]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final title = plain.length > 64 ? '${plain.substring(0, 64)}…' : plain;
    setState(() {
      session.insights.add(
        WorkspaceInsight(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title.isEmpty ? 'Kaydedilen AI içgörüsü' : title,
          content: source.text,
          createdAt: DateTime.now(),
          sourceMessageId: source.id,
        ),
      );
      session.updatedAt = DateTime.now();
    });
    await _store.saveSessions(_sessions);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Son yanıt içgörü kasasına kaydedildi.')),
    );
  }

  void _runMissionAction(String instruction) {
    final session = _selectedSession;
    if (session == null || session.messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Misyon kontrolü için önce bu çalışmada en az bir mesaj gönder.',
          ),
        ),
      );
      return;
    }
    _composerController.text = instruction;
    _composerController.selection = TextSelection.collapsed(
      offset: instruction.length,
    );
    Navigator.of(context).maybePop();
    _sendMessage();
  }

  Future<void> _openMissionControl() async {
    final actions =
        <({String title, String subtitle, IconData icon, String instruction})>[
          (
            title: 'Yönetici özeti',
            subtitle: 'Bağlamı, sonucu ve açık noktaları kısalt',
            icon: Icons.summarize_rounded,
            instruction: 'Bu çalışma oturumunun yönetici özetini hazırla. Bağlamı, en önemli bulguları, kararları, açık noktaları ve önerilen sonraki adımı net başlıklarla yaz.',
          ),
          (
            title: 'Karar kaydı',
            subtitle: 'Alternatifler ve gerekçelerle kararları kaydet',
            icon: Icons.account_tree_rounded,
            instruction: 'Bu çalışma oturumundaki kararları bir karar kaydı olarak çıkar. Her karar için seçenekleri, seçilen yönü, gerekçeyi ve varsayımları yaz. Eksik kararları ayrıca belirt.',
          ),
          (
            title: 'Risk taraması',
            subtitle: 'Riskleri, etkileri ve azaltma planını incele',
            icon: Icons.shield_outlined,
            instruction: 'Bu çalışma oturumu için kapsamlı bir risk taraması yap. Her risk için olasılık, etki, erken uyarı işareti ve somut azaltma adımı ver.',
          ),
          (
            title: 'Eylem planı',
            subtitle: 'Öncelikli, ölçülebilir uygulama planı üret',
            icon: Icons.rocket_launch_outlined,
            instruction: 'Bu çalışma oturumundaki bağlamı kullanarak önceliklendirilmiş bir eylem planı hazırla. Görevleri sıralı ve kontrol listesi biçiminde; her görev için beklenen çıktı ve başarı ölçütüyle yaz.',
          ),
        ];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: OxygenForgeTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
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
              const SizedBox(height: 18),
              const Text(
                'MİSYON KONTROL',
                style: TextStyle(
                  color: OxygenForgeTheme.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'AI çalışma aksiyonları',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Geçerli sohbet bağlamını kullanarak odaklanmış bir çalışma çıktısı üret.',
                style: TextStyle(
                  color: OxygenForgeTheme.muted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              ...actions.map(
                (action) => ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0x18FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x28FFFFFF)),
                    ),
                    child: Icon(action.icon, size: 20),
                  ),
                  title: Text(
                    action.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(action.subtitle),
                  trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
                  onTap: () => _runMissionAction(action.instruction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCommandCenter() async {
    final searchController = TextEditingController();
    var query = '';
    final commands =
        <({String label, String subtitle, IconData icon, VoidCallback action})>[
          (
            label: 'Yeni çalışma',
            subtitle: 'Boş bir AI çalışma alanı aç',
            icon: Icons.add_rounded,
            action: _newSession,
          ),
          (
            label: 'Çalışma panosu',
            subtitle: 'Notları ve görevleri yönet',
            icon: Icons.dashboard_customize_rounded,
            action: _openWorkspaceBoard,
          ),
          (
            label: 'Son yanıttan görev çıkar',
            subtitle: 'Madde adımlarını kontrol listesine ekle',
            icon: Icons.auto_fix_high_rounded,
            action: _extractTasksFromLastAnswer,
          ),
          (
            label: 'Son yanıtı içgörü olarak kaydet',
            subtitle: 'AI yanıtını kalıcı içgörü kasasına ekle',
            icon: Icons.bookmark_add_outlined,
            action: _saveLastAnswerAsInsight,
          ),
          (
            label: 'Misyon kontrol',
            subtitle: 'Özet, karar, risk ve eylem planı üret',
            icon: Icons.radar_rounded,
            action: _openMissionControl,
          ),
          (
            label: 'Sohbeti dışa aktar',
            subtitle: 'Geçerli oturumu Markdown olarak kopyala',
            icon: Icons.ios_share_rounded,
            action: _exportCurrentSession,
          ),
          (
            label: 'API profilleri',
            subtitle: 'Sağlayıcı ve model bağlantılarını yönet',
            icon: Icons.tune_rounded,
            action: _openSettings,
          ),
        ];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OxygenForgeTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final visible = commands.where((command) {
            final normalized = query.toLowerCase();
            return command.label.toLowerCase().contains(normalized) ||
                command.subtitle.toLowerCase().contains(normalized);
          }).toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                12,
                18,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 18),
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    onChanged: (value) =>
                        setSheetState(() => query = value.trim()),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Komut ara...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...visible.map(
                    (command) => ListTile(
                      leading: Icon(command.icon),
                      title: Text(
                        command.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(command.subtitle),
                      trailing: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        command.action();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    searchController.dispose();
  }

  Future<void> _sendMessage() async {
    final selectedAttachment = _attachment;
    final typedPrompt = _composerController.text.trim();
    final prompt = typedPrompt.isEmpty && selectedAttachment != null
        ? 'Bu görseli analiz et.'
        : typedPrompt;
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
      message: error
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('FormatException: ', ''),
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
      SnackBar(
        content: Text(
          'API profilleri kaydedildi. Aktif: ${next.activeProfile.name}',
        ),
      ),
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
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
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
    _composerController.selection = TextSelection.collapsed(
      offset: prompt.length,
    );
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
        SnackBar(
          content: Text(
            '${picked.name} eklendi. İstersen bir talimat yazıp gönder.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Görsel okunamadı: $error')));
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
        if (status == 'notListening' && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesli giriş kullanılamıyor: ${error.errorMsg}'),
          ),
        );
      },
    );
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu cihazda sesli giriş kullanılamıyor veya mikrofon izni verilmedi.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isListening = true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: 'tr_TR',
        listenMode: stt.ListenMode.dictation,
      ),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _composerController.text = result.recognizedWords;
          _composerController.selection = TextSelection.collapsed(
            offset: _composerController.text.length,
          );
        });
      },
    );
  }

  Future<void> _exportCurrentSession() async {
    final session = _selectedSession;
    if (session == null || session.messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dışa aktarmak için önce bir mesaj gönder.'),
        ),
      );
      return;
    }
    final buffer = StringBuffer('# ${session.title}\n\n');
    for (final message in session.messages) {
      final speaker = message.role == MessageRole.user
          ? 'Sen'
          : 'OxygenForge AI';
      buffer.writeln('**$speaker**');
      buffer.writeln(message.text);
      buffer.writeln();
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sohbet Markdown olarak panoya kopyalandı.'),
      ),
    );
  }

  Future<void> _regenerateLast() async {
    final session = _selectedSession;
    if (session == null || session.messages.isEmpty || _isTyping) return;
    final lastAssistantIndex = session.messages.lastIndexWhere(
      (message) => message.role == MessageRole.assistant,
    );
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
    final userIndex = session.messages.lastIndexWhere(
      (message) => message.role == MessageRole.user,
    );
    if (userIndex < 0) return;
    final prompt = session.messages[userIndex].text;
    setState(() {
      session.messages.removeAt(userIndex);
      _lastError = null;
    });
    _composerController.text = prompt;
    _composerController.selection = TextSelection.collapsed(
      offset: prompt.length,
    );
    await _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: OxygenForgeTheme.violetBright,
          ),
        ),
      );
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
    final visibleSessions = _visibleSessions;
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
          if (showLogo) ...[const ForgeLogo(), const SizedBox(height: 25)],
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _sessionSearchController,
            onChanged: _updateSessionQuery,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Çalışmalarda ara',
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              suffixIcon: _sessionQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _sessionSearchController.clear();
                        _updateSessionQuery('');
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: 'Aramayı temizle',
                    ),
            ),
          ),
          const SizedBox(height: 18),
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
                    child: Text(
                      'Henüz sohbet yok',
                      style: TextStyle(
                        color: OxygenForgeTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  )
                : visibleSessions.isEmpty
                ? const Center(
                    child: Text(
                      'Eşleşen çalışma bulunamadı',
                      style: TextStyle(
                        color: OxygenForgeTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleSessions.length,
                    padding: EdgeInsets.zero,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final session = visibleSessions[index];
                      return _SessionTile(
                        session: session,
                        selected: session.id == _selectedSessionId,
                        onTap: () => _selectSession(session.id),
                        onActions: () => _showSessionActions(session),
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
            leading: const Icon(
              Icons.tune_rounded,
              size: 19,
              color: OxygenForgeTheme.muted,
            ),
            title: const Text(
              'Ayarlar',
              style: TextStyle(color: OxygenForgeTheme.muted, fontSize: 13),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: OxygenForgeTheme.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace(bool isCompact) {
    final session = _selectedSession;
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: Column(
        children: [
          _WorkspaceHeader(
            isCompact: isCompact,
            minimal: true,
            title: session?.title ?? 'Yeni çalışma',
            profileName: _settings.activeProfile.name,
            model: _settings.effectiveModel,
            provider: _settings.provider,
            connected: _settings.apiKey.isNotEmpty,
            onSettings: _openSettings,
            onCommandCenter: _openCommandCenter,
            onExport: _exportCurrentSession,
            onRegenerate: _regenerateLast,
          ),
          Expanded(child: _buildConversation(session, compact: isCompact)),
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
    );
  }

  Widget _buildConversation(ChatSession? session, {required bool compact}) {
    final messages = session?.messages ?? <ChatMessage>[];
    if (messages.isEmpty) {
      return _WelcomeView(compact: compact, onPromptTap: _usePrompt);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        compact ? 14 : 18,
        compact ? 16 : 24,
        18,
      ),
      itemCount:
          messages.length + (_isTyping ? 1 : 0) + (_lastError != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == messages.length) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: TypingBubble(),
          );
        }
        if (_lastError != null &&
            index == messages.length + (_isTyping ? 1 : 0)) {
          return ErrorCard(
            exception: _lastError!,
            onRetry: _retryLastPrompt,
            onSettings: _openSettings,
          );
        }
        return MessageBubble(
          key: ValueKey(messages[index].id),
          message: messages[index],
        );
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
    required this.onCommandCenter,
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
  final VoidCallback onCommandCenter;
  final VoidCallback onExport;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    if (minimal) {
      return _MinimalHeader(
        title: title,
        profileName: profileName,
        provider: provider,
        model: model,
        connected: connected,
        onSettings: onSettings,
        onCommandCenter: onCommandCenter,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: FrostedPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        borderRadius: BorderRadius.circular(24),
        blur: 18,
        color: const Color(0xAD0A0A0A),
        borderColor: const Color(0x30FFFFFF),
        child: SizedBox(
          height: 54,
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
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.22),
                            end: Offset.zero,
                          ).animate(animation),
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
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: connected
                              ? OxygenForgeTheme.green
                              : OxygenForgeTheme.violetBright,
                        ),
                        const SizedBox(width: 5),
                        AnimatedSwitcher(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Text(
                            connected
                                ? '${provider.label}  ·  $model'
                                : '${provider.label} demo motoru',
                            key: ValueKey('${provider.name}-$model-$connected'),
                            style: const TextStyle(
                              color: OxygenForgeTheme.muted,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ModePill(
                label: connected ? 'Anahtar hazır' : 'Demo mod',
                connected: connected,
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onCommandCenter,
                tooltip: 'Komut merkezi',
                icon: const Icon(
                  Icons.keyboard_command_key_rounded,
                  color: OxygenForgeTheme.text,
                ),
              ),
              IconButton(
                onPressed: onRegenerate,
                tooltip: 'Son yanıtı yeniden üret',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: OxygenForgeTheme.muted,
                ),
              ),
              IconButton(
                onPressed: onExport,
                tooltip: 'Sohbeti kopyala',
                icon: const Icon(
                  Icons.ios_share_rounded,
                  color: OxygenForgeTheme.muted,
                ),
              ),
              IconButton(
                onPressed: onSettings,
                tooltip: 'Ayarlar',
                icon: const Icon(
                  Icons.tune_rounded,
                  color: OxygenForgeTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.session});

  final ChatSession session;

  @override
  Widget build(BuildContext context) {
    final assistantMessages = session.messages
        .where((message) => message.role == MessageRole.assistant)
        .toList();
    final totalThinking = assistantMessages.fold<Duration>(
      Duration.zero,
      (total, message) => total + (message.thinkingDuration ?? Duration.zero),
    );
    final thinkingLabel = totalThinking.inSeconds < 1
        ? '${totalThinking.inMilliseconds} ms'
        : '${(totalThinking.inMilliseconds / 1000).toStringAsFixed(1)} sn';
    return FrostedPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      borderRadius: BorderRadius.circular(20),
      blur: 20,
      color: OxygenForgeTheme.glassSoft,
      borderColor: OxygenForgeTheme.glassEdgeSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: OxygenForgeTheme.glassEdgeSoft),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'ÇALIŞMA BAĞLAMI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.15,
                  ),
                ),
              ),
              Text(
                '${session.insights.length} içgörü',
                style: const TextStyle(
                  color: OxygenForgeTheme.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _SummaryMetric(
                icon: Icons.forum_outlined,
                label: '${session.messages.length} mesaj',
              ),
              _SummaryMetric(
                icon: Icons.auto_awesome_rounded,
                label: '${assistantMessages.length} yanıt',
              ),
              _SummaryMetric(
                icon: Icons.psychology_alt_outlined,
                label: thinkingLabel,
              ),
              _SummaryMetric(
                icon: Icons.check_circle_outline_rounded,
                label:
                    '${session.tasks.where((task) => task.isCompleted).length}/${session.tasks.length} görev',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x16FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: OxygenForgeTheme.muted),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MinimalHeader extends StatelessWidget {
  const _MinimalHeader({
    required this.title,
    required this.profileName,
    required this.provider,
    required this.model,
    required this.connected,
    required this.onSettings,
    required this.onCommandCenter,
  });

  final String title;
  final String profileName;
  final AiProvider provider;
  final String model;
  final bool connected;
  final VoidCallback onSettings;
  final VoidCallback onCommandCenter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Builder(
            builder: (context) => _ReferenceCircleButton(
              icon: Icons.menu_rounded,
              tooltip: 'Menüyü aç',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Material(
              color: OxygenForgeTheme.referenceSurface,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: onSettings,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: OxygenForgeTheme.line),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    connected ? provider.label : profileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OxygenForgeTheme.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _ReferenceCircleButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Araçlar',
            onPressed: onCommandCenter,
          ),
        ],
      ),
    );
  }
}

class _ReferenceCircleButton extends StatelessWidget {
  const _ReferenceCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: OxygenForgeTheme.referenceSurface,
        shape: const CircleBorder(
          side: BorderSide(color: OxygenForgeTheme.line),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: Icon(icon, size: 25, color: OxygenForgeTheme.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.compact, required this.onPromptTap});

  final bool compact;
  final ValueChanged<String> onPromptTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 54 : 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 5),
          _ReferenceAction(
            icon: Icons.image_outlined,
            label: 'Görsel oluştur',
            prompt: 'Bir görsel oluşturmak istiyorum: ',
            onTap: onPromptTap,
          ),
          const SizedBox(height: 18),
          _ReferenceAction(
            icon: Icons.edit_outlined,
            label: 'Yaz veya düzenle',
            prompt: 'Şu metni daha açık ve etkili hale getir: ',
            onTap: onPromptTap,
          ),
          const SizedBox(height: 18),
          _ReferenceAction(
            icon: Icons.travel_explore_rounded,
            label: 'Web’de arama yap',
            prompt: 'Bu konu hakkında web araştırması için güvenilir kaynaklar ve arama başlıkları öner: ',
            onTap: onPromptTap,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _ReferenceAction extends StatelessWidget {
  const _ReferenceAction({
    required this.icon,
    required this.label,
    required this.prompt,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String prompt;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(prompt),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icon, color: OxygenForgeTheme.muted, size: 34),
            const SizedBox(width: 22),
            Text(
              label,
              style: const TextStyle(
                color: OxygenForgeTheme.muted,
                fontSize: 19,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.prompt,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final String prompt;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(prompt),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: width,
        child: FrostedPanel(
          padding: const EdgeInsets.all(17),
          borderRadius: BorderRadius.circular(20),
          blur: 16,
          color: const Color(0x9E0D0D0D),
          borderColor: const Color(0x2EFFFFFF),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x30FFFFFF)),
                ),
                child: Icon(
                  icon,
                  color: OxygenForgeTheme.violetBright,
                  size: 20,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: OxygenForgeTheme.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: OxygenForgeTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _WelcomeCapability extends StatelessWidget {
  const _WelcomeCapability({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x16FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: OxygenForgeTheme.glassEdgeSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: OxygenForgeTheme.text),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 15,
          color: OxygenForgeTheme.muted,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Sohbet geçmişin bu cihazda saklanır. API anahtarı eklemeden demo modunu deneyebilirsin.',
            style: const TextStyle(
              color: OxygenForgeTheme.muted,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onNewSession,
    required this.onExport,
    required this.onBoard,
    required this.onExtractTasks,
    required this.onMissionControl,
    required this.onProviders,
    required this.onCamera,
    required this.onGallery,
  });

  final VoidCallback onNewSession;
  final VoidCallback onExport;
  final VoidCallback onBoard;
  final VoidCallback onExtractTasks;
  final VoidCallback onMissionControl;
  final VoidCallback onProviders;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
        children: [
          _QuickActionChip(
            icon: Icons.add_rounded,
            label: 'Yeni çalışma',
            onPressed: onNewSession,
          ),
          const SizedBox(width: 8),
          _QuickActionChip(
            icon: Icons.ios_share_rounded,
            label: 'Dışa aktar',
            onPressed: onExport,
          ),
          const SizedBox(width: 8),
          _QuickActionChip(
            icon: Icons.dashboard_customize_rounded,
            label: 'Çalışma panosu',
            onPressed: onBoard,
          ),
          const SizedBox(width: 8),
          _QuickActionChip(
            icon: Icons.auto_fix_high_rounded,
            label: 'Görev çıkar',
            onPressed: onExtractTasks,
          ),
          const SizedBox(width: 8),
          _QuickActionChip(
            icon: Icons.radar_rounded,
            label: 'Misyon kontrol',
            onPressed: onMissionControl,
          ),
          const SizedBox(width: 8),
          _QuickActionChip(
            icon: Icons.hub_rounded,
            label: 'Bağlantılar',
            onPressed: onProviders,
          ),
          const SizedBox(width: 8),
          _QuickActionChip(
            icon: Icons.camera_alt_rounded,
            label: 'Kamera',
            onPressed: onCamera,
          ),
          const SizedBox(width: 8),
          _QuickActionChip(
            icon: Icons.photo_library_rounded,
            label: 'Görsel ekle',
            onPressed: onGallery,
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatefulWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_QuickActionChip> createState() => _QuickActionChipState();
}

class _QuickActionChipState extends State<_QuickActionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _attentionController;
  var _pressed = false;

  @override
  void initState() {
    super.initState();
    _attentionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
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
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onPressed();
              },
              borderRadius: BorderRadius.circular(17),
              child: AnimatedContainer(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _pressed
                      ? const Color(0x2BFFFFFF)
                      : const Color(0x17FFFFFF),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: _pressed
                        ? OxygenForgeTheme.glassEdge
                        : OxygenForgeTheme.glassEdgeSoft,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 15,
                        color: OxygenForgeTheme.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: OxygenForgeTheme.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 10, 30, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: OxygenForgeTheme.referenceSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isListening ? Colors.white : OxygenForgeTheme.line,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (attachmentName != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 4),
                      child: InputChip(
                        avatar: const Icon(Icons.image_outlined, size: 15),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 210),
                          child: Text(
                            attachmentName!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onDeleted: onClearAttachment,
                        side: BorderSide.none,
                        backgroundColor: const Color(0x18FFFFFF),
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ComposerControl(
                      onPressed: isTyping ? null : onGallery,
                      tooltip: 'Görsel ekle',
                      icon: Icons.add_rounded,
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) => onSend(),
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'OxygenForge AI’ye sor',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                    _ComposerControl(
                      onPressed: isTyping ? null : onVoice,
                      tooltip: isListening ? 'Dinlemeyi durdur' : 'Sesli giriş',
                      icon: isListening
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (context, value, _) {
                        final canSend =
                            value.text.trim().isNotEmpty ||
                            attachmentName != null;
                        return _ComposerControl(
                          onPressed: isTyping
                              ? null
                              : (canSend ? onSend : onVoice),
                          tooltip: canSend ? 'Gönder' : 'Sesli giriş',
                          icon: canSend
                              ? Icons.arrow_upward_rounded
                              : Icons.graphic_eq_rounded,
                          background: OxygenForgeTheme.referenceBlue,
                          foreground: Colors.white,
                          size: 60,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerControl extends StatelessWidget {
  const _ComposerControl({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    this.background,
    this.foreground,
    this.size = 54,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;
  final Color? background;
  final Color? foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background ?? Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Icon(
                icon,
                size: 30,
                color: foreground ?? OxygenForgeTheme.text,
              ),
            ),
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
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: OxygenForgeTheme.muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onActions,
  });

  final ChatSession session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? const Color(0x16FFFFFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        onLongPress: onActions,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: Icon(
          selected
              ? Icons.chat_bubble_rounded
              : Icons.chat_bubble_outline_rounded,
          size: 17,
          color: selected ? OxygenForgeTheme.text : OxygenForgeTheme.muted,
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? OxygenForgeTheme.text : OxygenForgeTheme.muted,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${session.messages.length} mesaj · ${_relativeDate(session.updatedAt)}',
          style: const TextStyle(color: OxygenForgeTheme.muted, fontSize: 10.5),
        ),
        trailing: IconButton(
          onPressed: onActions,
          tooltip: 'Çalışma işlemleri',
          icon: const Icon(
            Icons.more_horiz_rounded,
            size: 18,
            color: OxygenForgeTheme.muted,
          ),
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
  const _ConnectionCard({
    required this.connected,
    required this.provider,
    required this.onTap,
  });

  final bool connected;
  final AiProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OxygenForgeTheme.line),
        ),
        child: Row(
          children: [
            Icon(
              connected
                  ? Icons.check_circle_outline_rounded
                  : Icons.key_outlined,
              color: OxygenForgeTheme.muted,
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connected
                        ? '${provider.label} hazır'
                        : '${provider.label} demo',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    connected
                        ? 'Anahtar kaydedildi'
                        : 'Anahtar eklemek için aç',
                    style: const TextStyle(
                      color: OxygenForgeTheme.muted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: OxygenForgeTheme.muted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
