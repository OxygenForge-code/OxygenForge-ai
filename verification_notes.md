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

## Modern ana ekran uyumu QA (1.4.5)

Boş sohbet alanı artık mobil cihazlarda da ana ekranın çalışma alanı yaklaşımını sürdüren bir hero kartı, hızlı başlangıç önerileri ve gizlilik notu gösterir. Kompakt başlık, profil seçici ve bağlantı denetimleri yarı saydam siyah-beyaz yüzeylere uyarlandı. Geniş ekranda sohbet başlığı, yuvarlatılmış buzlu cam denetim çubuğu olarak sunulur; hızlı aksiyonlar Türkçeleştirildi ve öneri kartları ekran genişliğine göre tek veya iki sütuna yerleşir.

Sıfırlanma sonrası Flutter, Android SDK ve Java geliştirme araç zinciri yeniden kuruldu. `flutter analyze` temiz geçti ve toplam 14 test başarıyla tamamlandı. Final Android APK `versionName 1.4.5`, `versionCode 11` olarak üretildi. Paket içinde `INTERNET`, `RECORD_AUDIO` ve `CAMERA` izinleri doğrulandı; APK v2 imzası geçerli. SHA-256: `993ea7ae10247576e89ade9e106b802acfbdb5840d26322a4a2d6371b2c3f1b5`.

## Üretkenlik çalışma alanı QA (1.4.6)

Çalışma listesine oturum başlığı ve mesaj içeriği üzerinden arama eklendi. Oturumlar kalıcı şekilde sabitlenebilir; uzun basma veya işlem menüsü üzerinden yeniden adlandırılabilir ve silinebilir. Sabitlenmiş çalışmalar güncellenme zamanından önce sıralanır. Sohbet alanı yeni çalışma, dışa aktarma, bağlantı, kamera ve görsel ekleme hızlı komutları ile oturumdaki mesaj/AI yanıtı sayısını ve ölçülen toplam model bekleme süresini gösteren bir özet kartı içerir.

`flutter analyze` temiz geçti ve toplam 17 test başarıyla tamamlandı. Final Android APK `versionName 1.4.6`, `versionCode 12` olarak üretildi. Paket içinde `INTERNET`, `RECORD_AUDIO` ve `CAMERA` izinleri doğrulandı; APK v2 imzası geçerli. SHA-256: `4b705a8002283fbdbdcf37767b5b5ecc3061da7c8bf0f435c11b4d0876983ebd`.

## Komut merkezi ve çalışma panosu QA (1.4.7)

Her çalışma artık kalıcı notlara ve görev listesine sahiptir. Çalışma panosu not düzenleme, görev ekleme, görevi tamamlama ve silme akışlarını içerir. Son AI yanıtı numaralı ya da madde işaretli adımlar içeriyorsa, `Görev çıkar` komutu en fazla sekiz benzersiz adımı kaynak mesaja bağlı görevler olarak ekler. Komut merkezi; yeni çalışma, çalışma panosu, görev çıkarma, dışa aktarma ve API profil yönetimi işlemlerini arama alanıyla bir araya getirir.

`flutter analyze` temiz geçti ve toplam 17 test başarıyla tamamlandı. Final Android APK `versionName 1.4.7`, `versionCode 13` olarak üretildi. Paket içinde `INTERNET`, `RECORD_AUDIO` ve `CAMERA` izinleri doğrulandı; APK v2 imzası geçerli. SHA-256: `cda4da3318b9e6f520ad3732e8d94451d8fcbedc6619aa6bb482ba894caaaa51`.

## AI çalışma işletim sistemi QA (1.4.8)

Son AI yanıtı artık kaynak mesajına bağlı kalıcı bir içgörü olarak içgörü kasasına kaydedilebilir; kayıtlar çalışma panosunda görüntülenip silinebilir. Misyon kontrolü geçerli sohbet geçmişiyle çalışan dört odaklı üretim akışı sağlar: yönetici özeti, karar kaydı, risk taraması ve ölçülebilir eylem planı. Her misyon eylemi görünür bir kullanıcı istemi olarak sohbete eklenir; böylece kullanıcı modelden istenen çıktıyı ve kaynak bağlamını denetleyebilir.

`flutter analyze` temiz geçti ve toplam 17 test başarıyla tamamlandı. Final Android APK `versionName 1.4.8`, `versionCode 14` olarak üretildi. Paket içinde `INTERNET`, `RECORD_AUDIO` ve `CAMERA` izinleri doğrulandı; APK v2 imzası geçerli. SHA-256: `472889f5da20cd7a0479cc368499605ec9297fbdc942c2fd111a1d5abd4f29af`.

## Rafine mobil arayüz QA (1.4.9)

Mobil sohbet deneyimi yeni cam yüzey tokenlarıyla yeniden dengelendi. Başlık artık çalışma adı ile seçili sağlayıcı/modeli birlikte gösterir; oturum özeti mesaj, AI yanıtı, toplam düşünme süresi ve açık görev bilgisini kompakt metrik pill’leriyle sunar. Hızlı aksiyonlar mikro kartlara dönüştürüldü ve dokunuşta platform dokunsal geri bildirimi eklendi. Oluşturucu alanı durum göstergeli, katmanlı bir buzlu cam panel olarak yenilendi; mesaj kartları üst kimlik etiketi, saat damgası, daha derin cam kenarı ve iyileştirilmiş giriş hiyerarşisi kazandı.

Boş çalışma alanına üstten süzülen monokrom ışık katmanı, fikir/strateji/analiz yetenek etiketleri ve daha tutarlı cam derinliği eklendi. Yeni yüzeyler mevcut hareket azaltma davranışını korur. `flutter analyze` temiz geçti ve toplam 17 test başarıyla tamamlandı. Final Android APK `versionName 1.4.9`, `versionCode 15` olarak üretildi; paket kimliği `com.oxygenforge.oxygenforge_ai` doğrulandı ve APK Signature Scheme v2 imzası geçerli bulundu. Teslim APK SHA-256: `3c691094c0d907796f1cf99a19110c82dec83abe70688939e47d6725fd1d6452`.

## Tekrar etmeyen metin ve sade mobil arayüz QA (1.4.10)

Mesaj kartlarının giriş ve aşamalı metin animasyonları kaldırıldı. Asistan yanıtı artık mesaj balonu oluşturulduğu anda bütünüyle Markdown olarak render edilir; bu nedenle uygulama yeniden açıldığında veya `ListView` içinde aşağı-yukarı kaydırma sonucu widget yeniden kurulduğunda metin yeniden yazılmaz. Düşünme metni varsayılan kapalı, isteğe bağlı sade panel olarak tutuldu.

Mobil çalışma alanı düz siyah zemin, kompakt başlık, doğrudan sohbet listesi ve tek satırlı oluşturucu düzenine indirildi. Oturum özet kartı, hızlı aksiyon şeridi, arka plan ışık/dekor katmanları ve otomatik hareketler kaldırıldı. Boş durum iki temel başlangıç seçeneğine; çekmece içindeki çalışma satırları ve bağlantı durumu da animasyonsuz sade yüzeylere dönüştürüldü. `flutter analyze` temiz geçti; tam regresyon paketi toplam 18 testle başarılı tamamlandı. Final Android APK `versionName 1.4.10`, `versionCode 16` olarak üretildi, paket kimliği `com.oxygenforge.oxygenforge_ai` doğrulandı ve APK Signature Scheme v2 imzası geçerli bulundu. Teslim APK SHA-256: `e90fa6064cb29b121fff4ba3c8cbb1ef99120b3bc54f5eee8be890b6725966e6`.

## Referans minimal mobil arayüz QA (1.4.11)

Paylaşılan referansın geometrisi uygulamaya uyarlandı: üstte koyu dairesel menü ve araç kontrolleri arasında seçili profili gösteren geniş kapsül; boş sohbet alanının alt bölgesinde `Görsel oluştur`, `Yaz veya düzenle` ve `Web’de arama yap` aksiyonları; en altta ekleme, metin, mikrofon ve mavi birincil aksiyon içeren büyük kapsül oluşturucu bulunur. Ana sohbetin yanı sıra çekmece, çalışma panosu, komut merkezi, misyon kontrolü ve ayar yüzeyleri düz kömür renkli paneller, ince gri kenarlar ve ortak yuvarlatılmış geometriyle birleştirildi.

Mesaj metni doğrudan render edildiğinden önceki yeniden canlanma düzeltmesi korunur. `flutter analyze` temiz geçti ve tam regresyon paketi toplam 18 testle başarılı tamamlandı. Final Android APK `versionName 1.4.11`, `versionCode 17` olarak üretildi; paket kimliği `com.oxygenforge.oxygenforge_ai` doğrulandı ve APK Signature Scheme v2 imzası geçerli bulundu. Teslim APK SHA-256: `e3623287877d9768e1ea819c2fe00cfc68dc384e29bafd79927aa100cf30cfe1`.

## Premium mobil arayüz QA (1.4.12)

Üst kontrol şeridi, seçili sağlayıcı/model bilgisini, aktif bağlantı göstergesini ve dokunsal erişimi bir araya getiren katmanlı bir çalışma kapsülüne dönüştürüldü. Dairesel menü/araç düğmeleri koyu gradyan, ince parlak kenar ve derinlik gölgesi kazandı. Boş sohbet alanına OxygenForge enerji halkası, güçlü marka başlığı ve her biri mavi odaklı ikon, açıklama ve yön oku taşıyan görev kartları eklendi.

Oluşturucu; daha derin kapsül yüzey, açık kenar, gölgeli mavi ana aksiyon ve dokunsal kontrollerle yükseltildi. Çekmece, komut merkezi, çalışma panosu, misyon kontrolü ve ayar yüzeyleri ortak tema tokenları sayesinde aynı koyu, premium sistemde kalır. Mesaj metninin yeniden canlanmasını önleyen doğrudan render akışı korunur. `flutter analyze` temiz geçti ve tam regresyon paketi toplam 18 testle başarılı tamamlandı. Final Android APK `versionName 1.4.12`, `versionCode 18` olarak üretildi; paket kimliği `com.oxygenforge.oxygenforge_ai` doğrulandı ve APK Signature Scheme v2 imzası geçerli bulundu. Teslim APK SHA-256: `8ada95715f58312276668a127545b5dead63dd84c279a66bf10ce6c9e42526fa`.
