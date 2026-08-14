# OxygenForge AI

OxygenForge AI, fikirleri netleştirmek ve üretime taşımak için tasarlanmış, Flutter tabanlı odaklı bir AI çalışma alanıdır. Uygulama koyu temalı bir sohbet arayüzü, yerel sohbet geçmişi, başlangıç prompt kartları, demo yanıt motoru ve OpenAI uyumlu API bağlantısı sunar.

> **Durum:** MVP arayüzü ve çalışan sohbet akışı hazırdır. API anahtarı eklenmediğinde uygulama demo modunda çalışır; anahtar eklendiğinde OpenAI uyumlu bir chat-completions endpoint'ine bağlanır.

## Öne çıkan özellikler

| Özellik | Açıklama |
| --- | --- |
| Odaklı sohbet alanı | OxygenForge markasına uygun koyu, mor ve cyan aksanlı responsive arayüz |
| Demo motoru | API anahtarı olmadan ürün akışını deneyebilmek için yerel örnek yanıtlar |
| OpenAI uyumlu bağlantı | Endpoint, model ve API anahtarı ayarlar panelinden yapılandırılabilir |
| Yerel geçmiş | Sohbet oturumları ve ayarlar `shared_preferences` ile cihazda saklanır |
| Başlangıç kartları | Fikir geliştirme, kod düzeltme, plan oluşturma ve metin iyileştirme akışları |
| Responsive layout | Geniş ekranlarda kenar çubuğu, dar ekranlarda drawer tabanlı navigasyon |

## Teknoloji yığını

Uygulama Flutter 3.47 ve Dart 3.13 ile oluşturuldu. Ağ istekleri için `http`, yerel ayarlar ve sohbet geçmişi için `shared_preferences` kullanılır. Proje Android, iOS, Web ve Linux hedeflerini içerir.

## Kurulum

Flutter SDK'nın kurulu olduğu bir ortamda aşağıdaki komutlar yeterlidir:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Web release çıktısı almak için:

```bash
flutter build web --release
```

## Gerçek AI modeline bağlanma

Uygulama ilk açıldığında demo modundadır. Kenar çubuğundaki **Ayarlar** bölümünden aşağıdaki alanları doldurup **Ayarları kaydet** düğmesine basın.

| Alan | Örnek |
| --- | --- |
| API anahtarı | `sk-...` |
| OpenAI uyumlu endpoint | `https://api.openai.com/v1/chat/completions` |
| Model | `gpt-4o-mini` |

Uygulama, endpoint'e `Authorization: Bearer ...` başlığıyla ve `messages` dizisini içeren standart chat-completions gövdesiyle POST isteği gönderir. Farklı bir sağlayıcı kullanılıyorsa sağlayıcının OpenAI uyumluluk ve CORS koşulları kontrol edilmelidir.

> **Güvenlik notu:** API anahtarını doğrudan istemci uygulamasında saklamak yalnızca prototip ve kişisel kullanım için uygundur. Üretim ortamında anahtarın sunucu tarafında tutulması ve Flutter istemcisinin güvenli bir backend üzerinden konuşması önerilir.

## Proje yapısı

| Yol | Sorumluluk |
| --- | --- |
| `lib/main.dart` | Uygulama giriş noktası ve MaterialApp kurulumu |
| `lib/app_theme.dart` | OxygenForge renk paleti, tema ve ortak kart bileşenleri |
| `lib/screens/home_screen.dart` | Ana çalışma alanı, sidebar, composer, ayarlar ve sohbet akışı |
| `lib/models/chat_models.dart` | Mesaj, oturum ve ayar veri modelleri |
| `lib/services/ai_service.dart` | Demo yanıt motoru ve OpenAI uyumlu HTTP istemcisi |
| `lib/services/local_store.dart` | Sohbet ve ayarların yerel JSON depolaması |
| `lib/widgets/` | Logo, mod göstergesi ve mesaj balonu bileşenleri |
| `test/widget_test.dart` | Karşılama ekranı smoke testi |

## Doğrulama

Proje üzerinde `flutter analyze`, `flutter test` ve `flutter build web --release` komutları başarıyla çalıştırılmıştır. Tarayıcı kontrolünde OxygenForge AI başlığı, demo mod göstergesi, karşılama kartları, sohbet geçmişi alanı ve mesaj composer'ı doğru şekilde render edilmiştir. Ayrıntılı QA notları `verification_notes.md` dosyasındadır.

## GitHub

Proje, [OxygenForge-code/OxygenForge-ai](https://github.com/OxygenForge-code/OxygenForge-ai) repository'si temel alınarak oluşturulmuştur.

## Çok sağlayıcılı AI desteği

OxygenForge AI artık tek bir sağlayıcıya bağlı değildir. Ayarlar panelinden sağlayıcı ve model seçilebilir; her sağlayıcının anahtarı ayrı olarak yerel depolamada tutulur. Sağlayıcı değiştirildiğinde endpoint ve varsayılan model otomatik doldurulur, ancak istersen her alanı değiştirebilirsin.

| Sağlayıcı | Entegrasyon biçimi | Varsayılan model |
| --- | --- | --- |
| OpenAI | Chat Completions | `gpt-4o-mini` |
| Google Gemini | Native `generateContent` | `gemini-2.5-flash` |
| Groq | OpenAI uyumlu | `llama-3.3-70b-versatile` |
| OpenRouter | OpenAI uyumlu model router'ı | `openai/gpt-4o-mini` |
| Anthropic | Native Messages API | `claude-3-5-haiku-latest` |
| Mistral | OpenAI uyumlu | `mistral-small-latest` |
| Together AI | OpenAI uyumlu | `meta-llama/Llama-3.3-70B-Instruct-Turbo` |
| DeepSeek | OpenAI uyumlu | `deepseek-chat` |
| Custom API | Özel OpenAI uyumlu endpoint | `your-model` |

OpenAI uyumlu sağlayıcılarda `Authorization: Bearer ...` ve `messages[]` sözleşmesi kullanılır. Gemini için native `contents[]` ve `candidates[]` eşlemesi; Anthropic için `x-api-key`, `anthropic-version` ve native `content[]` eşlemesi uygulanır. Sağlayıcı adaptörleri ağ çağrısını test etmek için mock HTTP testleriyle doğrulanmıştır.

## Ek üretkenlik özellikleri

Sohbet başlığında aktif sağlayıcı ve model görünür. Son AI yanıtı tek tuşla yeniden üretilebilir, sohbet Markdown olarak panoya aktarılabilir ve asistan yanıtı ayrı olarak kopyalanabilir. Ayarlar paneli sistem promptu ve yaratıcılık sıcaklığını da yönetir.

Çok sağlayıcılı API doğrulama notları `provider_docs_notes.md` dosyasında tutulur.

## Material 3 ve bağlantı kurtarma

Arayüz Material 3 tema tokenları, yüzey katmanları, `CardThemeData`, modern butonlar, alt sayfalar, snackbar ve bağlantı kartlarıyla yenilenmiştir. Sağlayıcı bağlantısı başarısız olduğunda uygulama artık ham exception metnini tek satırlık snackbar'a sıkıştırmak yerine hatayı sınıflandırılmış bir kartta gösterir.

Groq ekran görüntüsündeki `SocketFailed` ve `Failed host lookup` durumu artık **Bağlantı kurulamadı** başlığıyla, DNS/internet kontrol önerisiyle ve **Tekrar dene** / **Ayarları kontrol et** aksiyonlarıyla gösterilir. Kimlik doğrulama, rate limit, geçersiz istek, sunucu ve JSON çözümleme hataları da ayrı kullanıcı mesajlarına ayrılır.

## Sade sohbet deneyimi ve zengin içerik

AI ve kullanıcı mesajları artık gerçek Markdown olarak render edilir. `**kalın**`, `*italik*`, başlıklar, sıralı/sırasız listeler, alıntılar, inline kod ve kod blokları ham karakter olarak görünmez; uygulama içinde tipografik olarak biçimlendirilir. Bağlantılar dokunulduğunda panoya kopyalanır ve asistan yanıtları Markdown olarak kopyalanabilir.

Composer sadeleştirildi. Sağlayıcılar, kamera ve galeriden görsel seçme hızlı aksiyon çipleriyle erişilebilir; mikrofon düğmesi Türkçe sesli girişi metne dönüştürür. Seçilen görseller OpenAI uyumlu vision formatına, Gemini `inlineData` formatına veya Anthropic base64 image formatına çevrilerek ilgili sağlayıcıya gönderilir. Görsel tek başına gönderilirse varsayılan talimat `Bu görseli analiz et.` olur.

Android için internet, kamera ve mikrofon izinleri; iOS için mikrofon, kamera ve fotoğraf kütüphanesi kullanım açıklamaları tanımlanmıştır.

## Minimal mobil arayüz

Mobil compact görünüm referans tasarıma göre sadeleştirilmiştir. Üst barda dairesel menü düğmesi, `Groq API` benzeri aktif sağlayıcı pill’i ve tek dairesel bağlantı düğmesi bulunur. Boş çalışma alanında büyük karşılama kartları gösterilmez; dikkat alt hızlı aksiyonlara ve composer’a bırakılır.

Alt bölümde `Try Connectors`, `Open Camera` ve `Choose Image` çipleri bulunur. Composer, `+` görsel ekleme, mikrofon ve büyük dairesel gönderme düğmesiyle tek satırlı ve odaklı bir kullanım sunar.

## Çoklu API profilleri

Her sağlayıcı için tek anahtar saklamak yerine birden fazla bağımsız API profili oluşturabilirsin. Her profil kendi sağlayıcısını, profil adını, API anahtarını, endpoint'ini, modelini, sıcaklık ayarını ve sistem promptunu taşır. Profiller cihazdaki yerel depoda kalıcı olarak tutulur; seçilen profil uygulamanın aktif sağlayıcısı olur.

`API profilleri` ekranından yeni profil ekleyebilir, düzenleyebilir, silebilir, aktif profilini değiştirebilir ve kısa bir istek göndererek bağlantıyı test edebilirsin. Eski tek sağlayıcılı ayarlar açılışta otomatik olarak ayrı profil kayıtlarına dönüştürülür.
