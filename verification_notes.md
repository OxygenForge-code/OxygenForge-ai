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

## Minimal mobil arayüz QA

Mobil compact görünüm referanstaki siyah ve sade kompozisyona dönüştürüldü. Üstte dairesel menü düğmesi, sağlayıcı API pill’i ve tek dairesel bağlantı aksiyonu bulunur. Boş çalışma alanında karşılama kartları gizlenir; altta `Try Connectors`, `Open Camera`, `Choose Image` çipleri ve büyük `Ask OxygenForge AI…` composer görünür.

Final Android release APK `versionName 1.3.0`, `versionCode 5` olarak üretildi. `INTERNET`, `RECORD_AUDIO` ve `CAMERA` izinleri pakette doğrulandı. APK v2 imzası geçerli. SHA-256: `0ce477f3c8b3c70cfa9f0ab084309829452cd5d7e0d94ddf86b9a368da7abeb0`.

## Çoklu API profil QA

`AppSettings` çoklu `ApiProfile` listesi ve seçili profil kimliğiyle genişletildi. Her profil sağlayıcı, anahtar, endpoint, model, sıcaklık ve sistem promptu bilgilerini taşır. V2 ayarları profil listesine migrate edilir. Ayar ekranı profil ekleme, düzenleme, silme, seçme ve gerçek bağlantı testi sağlar.

Final Android release APK `versionName 1.4.0`, `versionCode 6` olarak üretildi. `flutter analyze` temiz geçti ve 8 test başarıyla tamamlandı. Paket içinde `INTERNET`, `RECORD_AUDIO` ve `CAMERA` izinleri bulunuyor; APK v2 imzası doğrulandı. SHA-256: `564c4816699ea9b90e9abbbb4c9833013c3c18838f7994609a742f56dc6b58b4`.

## Görsel model uyumluluğu QA (1.4.1)

Görsel attachment gönderilmeden önce seçili sağlayıcı ve modelin görüntü desteği denetlenir. Groq içinde `llama-3.3-70b-versatile` gibi metin odaklı modeller ağ isteği yapılmadan engellenir; kullanıcı, tekrar denemek yerine doğrudan görsel destekleyen model seçimine yönlendirilir. Groq `llama-3.2-11b-vision-preview` gibi uyumlu modeller için istek gövdesi OpenAI uyumlu çok parçalı `content` alanıyla üretilir.

`flutter analyze` temiz geçti ve toplam 10 test başarıyla tamamlandı. Final Android APK `versionName 1.4.1`, `versionCode 7` olarak üretildi. Paket içinde `INTERNET`, `RECORD_AUDIO` ve `CAMERA` izinleri doğrulandı; APK v2 imzası geçerli. SHA-256: `b360f253482e79d0b85a9ea61712b561e91a80894bf1863ea13b7a15f92d2a8c`.

## İç düşünce filtresi ve monokrom tema QA (1.4.2)

OpenAI uyumlu sağlayıcılar, Gemini ve Anthropic yanıtları ekranda gösterilmeden önce işlenir. `<think>`, `<thinking>`, `<analysis>`, `<reasoning>` ve `<thought>` blokları ile tek başına kalan etiketleri temizlenir; Markdown içeren görünür yanıt korunur. Uygulamanın merkezi renk tokenları siyah, beyaz ve nötr gri tonlarına dönüştürüldü; önceki mor, cyan, yeşil ve kırmızı vurgu renkleri kaldırıldı.

`flutter analyze` temiz geçti ve toplam 12 test başarıyla tamamlandı. Final Android APK `versionName 1.4.2`, `versionCode 8` olarak üretildi. Paket içinde `INTERNET`, `RECORD_AUDIO` ve `CAMERA` izinleri doğrulandı; APK v2 imzası geçerli. SHA-256: `9bd9b7266d2854c0ef61fda5d85201718a32943022a03219bbcbb17f2d4f0dcd`.

## Düşünme görünümü ve hareketli arayüz QA (1.4.3)

Sağlayıcı yanıtlarında bulunan `<think>`, `<thinking>`, `<analysis>`, `<reasoning>` ve `<thought>` blokları görünür yanıttan ayrıştırılır, sohbet mesajında kalıcı olarak saklanır ve `Modelin düşünme süreci` başlıklı varsayılan açık panelde Markdown olarak gösterilir. Panel kullanıcı tarafından açılıp kapatılabilir; ana yanıt ve düşünme metni birlikte kopyalanabilir.

Mesajlar girişte kayma/sönme hareketiyle görünür. Düşünme paneli, başlık ve durum metinleri akıcı geçişler kullanır; yazıyor göstergesi nabız şeklinde çalışır. Hızlı aksiyonlar, oturum seçimi, bağlantı durumu ve oluşturucu alan basma, ölçek, ışık ve ikon geçişleriyle hareketlendirildi. Sistem seviyesinde hareket azaltma tercihi etkin olduğunda bu hareketler devre dışı kalır.

`flutter analyze` temiz geçti ve toplam 14 test başarıyla tamamlandı. Final Android APK `versionName 1.4.3`, `versionCode 9` olarak üretildi. Paket içinde `INTERNET`, `RECORD_AUDIO` ve `CAMERA` izinleri doğrulandı; APK v2 imzası geçerli. SHA-256: `1e87cab856ca72f941109679ca0ada2182a5c014a91c05ab3ad8542f7e651abf`.

## Düşünme süresi ve buzlu cam sohbet QA (1.4.4)

Asistan yanıtı beklenirken geçen süre ölçülür ve `Düşündü` rozeti olarak mesaj kartının üstünde gösterilir. Bu süre sohbet geçmişinin JSON kaydında saklanır. Asistan yanıtı kartı girdikten sonra metin kısa bir gecikmeyle aşamalı biçimde görünür; önceki mesajlar kimlikleri üzerinden korunarak tekrar oynatılmaz.

Sohbet mesajları ve ayar kartları siyah-beyaz buzlu cam panel yapısına geçirildi. Mesaj alanında ambient beyaz ışık lekeleri, yarı saydam koyu yüzeyler, beyaz cam kenarlar ve arka plan bulanıklığı kullanılır. Kartın görünmesinden sonra metin açılışı 150 ms gecikmeyle başlar. `flutter analyze` temiz geçti ve toplam 14 test başarıyla tamamlandı. Final Android APK `versionName 1.4.4`, `versionCode 10` olarak üretildi. Paket içinde `INTERNET`, `RECORD_AUDIO` ve `CAMERA` izinleri doğrulandı; APK v2 imzası geçerli. SHA-256: `d8ac2293ce0795f50b76c617c94f240925abeaef473cf06da6ceaac48f902314`.
