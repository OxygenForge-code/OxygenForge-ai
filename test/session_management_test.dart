import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oxygenforge_ai/models/chat_models.dart';
import 'package:oxygenforge_ai/services/local_store.dart';

void main() {
  ChatSession session({required String id, required bool isPinned}) {
    final now = DateTime(2026, 8, 15, 12);
    return ChatSession(
      id: id,
      title: 'Ürün stratejisi',
      createdAt: now,
      updatedAt: now,
      isPinned: isPinned,
      notes: 'Teklif dosyasını cuma günü gözden geçir.',
      messages: <ChatMessage>[
        ChatMessage(
          id: '$id-message',
          role: MessageRole.user,
          text: 'Yeni ürün stratejisini planla.',
          createdAt: now,
        ),
      ],
      tasks: <WorkspaceTask>[
        WorkspaceTask(
          id: '$id-task',
          title: 'Rakipleri karşılaştır',
          createdAt: now,
          sourceMessageId: '$id-message',
        ),
      ],
    );
  }

  test('sabitlenmiş oturum JSON dönüşümünde korunur', () {
    final original = session(id: 'pinned', isPinned: true);

    final restored = ChatSession.fromJson(original.toJson());

    expect(restored.title, 'Ürün stratejisi');
    expect(restored.isPinned, isTrue);
    expect(restored.messages.single.text, 'Yeni ürün stratejisini planla.');
    expect(restored.notes, 'Teklif dosyasını cuma günü gözden geçir.');
    expect(restored.tasks.single.title, 'Rakipleri karşılaştır');
    expect(restored.tasks.single.sourceMessageId, 'pinned-message');
  });

  test('eski oturum kayıtları sabitlenmemiş olarak güvenle yüklenir', () {
    final restored = ChatSession.fromJson(<String, dynamic>{
      'id': 'legacy',
      'title': 'Eski çalışma',
      'createdAt': DateTime(2026, 8, 15).toIso8601String(),
      'updatedAt': DateTime(2026, 8, 15).toIso8601String(),
      'messages': <Object>[],
    });

    expect(restored.isPinned, isFalse);
    expect(restored.notes, isEmpty);
    expect(restored.tasks, isEmpty);
  });

  test('sabitlenmiş oturum cihazda kaydedilip yeniden yüklenir', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = LocalStore();

    await store.saveSessions(<ChatSession>[session(id: 'persisted', isPinned: true)]);
    final restored = await store.loadSessions();

    expect(restored, hasLength(1));
    expect(restored.single.isPinned, isTrue);
    expect(restored.single.messages, hasLength(1));
    expect(restored.single.notes, 'Teklif dosyasını cuma günü gözden geçir.');
    expect(restored.single.tasks.single.title, 'Rakipleri karşılaştır');
  });
}
