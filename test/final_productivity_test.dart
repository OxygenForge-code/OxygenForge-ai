import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oxygenforge_ai/models/chat_models.dart';
import 'package:oxygenforge_ai/services/local_store.dart';

void main() {
  ApiProfile profile() {
    final now = DateTime(2026, 8, 15);
    return ApiProfile(
      id: 'final-profile',
      name: 'Final test',
      provider: AiProvider.groq,
      apiKey: 'test-key',
      createdAt: now,
      updatedAt: now,
    );
  }

  test('çalışma modu seçimi ayarlarda korunur', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = LocalStore();
    final settings = AppSettings(
      profiles: <ApiProfile>[profile()],
      selectedProfileId: 'final-profile',
      workMode: WorkMode.decide,
    );

    await store.saveSettings(settings);
    final restored = await store.loadSettings();

    expect(restored.workMode, WorkMode.decide);
    expect(restored.workMode.label, 'Karar');
    expect(restored.workMode.instruction, contains('ölçütlere göre'));
  });

  test('özel istem kitaplığı cihazda kaydedilip yeniden yüklenir', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = LocalStore();
    final template = PromptTemplate(
      id: 'prompt-1',
      title: 'Toplantı özeti',
      content: 'Bu notları kararlar ve aksiyonlar halinde özetle: ',
      createdAt: DateTime(2026, 8, 15),
    );

    await store.savePromptTemplates(<PromptTemplate>[template]);
    final restored = await store.loadPromptTemplates();

    expect(restored, hasLength(1));
    expect(restored.single.title, 'Toplantı özeti');
    expect(restored.single.content, contains('aksiyonlar'));
  });

  test('metin dosyası bağlamı kaynak adı ve içerik sınırını taşır', () {
    const document = DocumentAttachment(
      name: 'strateji.md',
      mimeType: 'text/markdown',
      content: '# Strateji\nÖnce kullanıcı görüşmeleri yapılacak.',
    );

    expect(document.characterCount, greaterThan(20));
    expect(document.promptBlock, contains('strateji.md'));
    expect(document.promptBlock, contains('kullanıcı görüşmeleri'));
  });
}
