# Çok sağlayıcılı API doğrulama notları

14 Ağustos 2026 tarihinde resmi sağlayıcı dokümanları kontrol edildi.

| Sağlayıcı | Doğrulanan sözleşme |
| --- | --- |
| Google Gemini | `POST https://generativelanguage.googleapis.com/v1beta/{model=models/*}:generateContent`; istek gövdesinde `contents[]`, isteğe bağlı `systemInstruction` ve `generationConfig` bulunur. Yanıt metni `candidates[]` içindeki adayın `content.parts[]` alanındaki `text` parçasından alınır. |
| OpenAI | `POST /chat/completions` chat geçmişindeki `messages[]` alanını alır; kimlik doğrulama `Authorization: Bearer ...` biçimindedir. Yanıt metni `choices[0].message.content` alanından alınır. OpenAI güncel dokümanı yeni projelerde Responses API'yi de önerse de bu uygulama çok sağlayıcılı uyumluluk için Chat Completions sözleşmesini kullanır. |

Kaynaklar: [Gemini GenerateContent API](https://ai.google.dev/api/generate-content), [OpenAI Create chat completion](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create).

## Ek sağlayıcılar

| Sağlayıcı | Doğrulanan sözleşme |
| --- | --- |
| Groq | OpenAI uyumlu yapı kullanır; resmi doküman `base_url` olarak `https://api.groq.com/openai/v1` değerini gösterir. Uygulama aynı `Authorization: Bearer ...` ve `messages[]` sözleşmesini kullanabilir. Groq dokümanı bazı OpenAI alanlarının desteklenmediğini, bu nedenle istek gövdesinin temel ve uyumlu tutulması gerektiğini belirtir. |
| Anthropic | Claude Messages API için ayrı adaptör gerekir; resmi API referansı `POST /v1/messages` ve sağlayıcıya özgü mesaj/yanıt biçimini kullanır. Bu adaptör `x-api-key`, `anthropic-version` ve `messages[]` alanlarını sağlayıcıya özel şekilde göndermelidir. |

Ek kaynaklar: [Groq OpenAI Compatibility](https://console.groq.com/docs/openai), [Anthropic Messages API](https://platform.claude.com/docs/en/api/messages).
