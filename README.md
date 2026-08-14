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
