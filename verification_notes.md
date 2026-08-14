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

## Kullanıcı hata görüntüsü

1080×198 piksel, yatay ve iki örtüşen parça halinde incelenen ekran görüntüsünde şu hata doğrulandı: `Bağlantı kurulamadı: ClientException with SocketFailed host lookup: 'api.groq.com' (OS Error: No address associated with hostname, ...)`. Bu, uygulama isteği göndermeden önce `api.groq.com` alan adının cihaz/sandbox DNS çözümlemesinde başarısız olduğunu gösterir; bu nedenle arayüzde hata türü, sağlayıcı, yeniden deneme ve endpoint kontrolü görünür hale getirilecektir.

## Android release internet izni düzeltmesi

Release APK manifesti incelendiğinde önceki pakette yalnızca debug manifestinde bulunan `android.permission.INTERNET` izninin release manifestine aktarılmadığı doğrulandı. Ana manifest güncellendi ve yeni APK içinde `aapt2 dump permissions` çıktısında `android.permission.INTERNET` görünür hale geldi.

Yeni 1.2.1 APK'da paket metadata'sı `versionName 1.2.1`, `versionCode 4` olarak doğrulandı; APK imzası v2 ile doğrulandı. Üst durum göstergesi de gerçek bağlantı sağlığını yanlış biçimde `Bağlı` olarak göstermemesi için `Anahtar hazır` şeklinde güncellendi.

## Rich composer ve Markdown QA

Kullanıcı ve asistan mesajları `flutter_markdown_plus` ile gerçek Markdown olarak render edilir. Kalın, italik, başlık, liste, alıntı, inline kod ve kod blokları için özel OxygenForge stil tablosu tanımlandı. Composer’a sağlayıcılar, kamera, görsel seçme, mikrofon, attachment chip ve sade gönderme aksiyonları eklendi.

Seçilen görseller OpenAI uyumlu `image_url`, Gemini `inlineData` ve Anthropic base64 image bloklarına dönüştürülür. Türkçe sesli giriş `speech_to_text` ile uygulanır. Kamera, galeri, mikrofon, API ve attachment değişikliklerinden sonra `flutter analyze` temiz geçti ve 5 test başarıyla tamamlandı.

## Final 1.3.0 release doğrulaması

Final APK `versionName 1.3.0`, `versionCode 5` olarak üretildi. Paket içinde `INTERNET`, `RECORD_AUDIO` ve `CAMERA` izinleri doğrulandı. APK v2 imzası geçerli. `flutter analyze` temiz geçti ve 5 test başarıyla tamamlandı.

Release build sırasında sandbox belleğine uygun Gradle ayarları kullanıldı: tek worker, daemon kapalı, `-Xmx1024m` ve `MaxMetaspaceSize=512m`. Final APK SHA-256: `c5e58af7fa9d851bae8454fceccefaf0acedc202ae7a26209263f282c397b80a`.
