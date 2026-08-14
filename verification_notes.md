# Görsel doğrulama notları

14 Ağustos 2026 tarihinde release web build, yerel Flutter web sunucusunda tarayıcı ile kontrol edildi.

- Sayfa başlığı `OxygenForge AI` olarak doğru yükleniyor.
- Koyu arayüz, mor/cyan gradyanlı OxygenForge markası ve demo mod göstergesi görünür.
- Sol kenar çubuğunda `Yeni çalışma`, `ÇALIŞMA ALANI`, `Henüz sohbet yok`, `Demo modu` ve `Ayarlar` bölümleri görünüyor.
- Karşılama alanında `Fikrini ateşle.` başlığı, açıklama, dört başlangıç kartı ve mesaj yazma alanı görünüyor.
- `flutter build web --release` başarılı tamamlandı.
- `flutter analyze` ve `flutter test` başarılı tamamlandı.

## Çok sağlayıcılı sürüm QA

Çok sağlayıcılı servis katmanı mock HTTP testleriyle doğrulandı. OpenAI uyumlu Groq request/response eşlemesi, Gemini `generateContent` eşlemesi ve Anthropic Messages API header/response eşlemesi başarıyla test edildi. `flutter analyze` temiz geçti ve toplam dört widget/servis testi başarıyla tamamlandı.

Arayüzde sağlayıcı seçimi, sağlayıcı bazlı anahtar saklama, model ve endpoint düzenleme, sistem promptu, sıcaklık ayarı, mesaj kopyalama, sohbeti Markdown olarak panoya aktarma ve son yanıtı yeniden üretme kontrolleri eklendi.
