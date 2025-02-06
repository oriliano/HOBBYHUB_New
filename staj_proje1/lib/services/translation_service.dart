// lib/services/translation_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TranslationService {
  static final String apiUrl = dotenv.env['TRANSLATE_API_URL'] ??
      'https://translation.googleapis.com/language/translate/v2';
  static final String apiKey = dotenv.env['TRANSLATE_API_KEY'] ?? '';
  static final Map<String, String> _cache = {};

  // Metni çevir ve önbelleğe al
  static Future<String> translateText(String text, String targetLang) async {
    String cacheKey = 'tr-$targetLang-$text';
    if (_cache.containsKey(cacheKey)) {
      print("Çeviri önbellekten alındı: $cacheKey"); // Debug çıktısı
      return _cache[cacheKey]!;
    }

    print("Çeviri API çağrısı yapılıyor: $text"); // Debug çıktısı

    final response = await http.post(
      Uri.parse('$apiUrl?key=$apiKey'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'q': text,
        'target': targetLang,
        'format': 'text',
        'source': 'tr', // Kaynak dili Türkçe olarak belirtiyoruz
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final translatedText =
          jsonBody['data']['translations'][0]['translatedText'];
      _cache[cacheKey] = translatedText;
      print("Çeviri başarılı: $translatedText"); // Debug çıktısı
      return translatedText;
    } else {
      print("Çeviri API hatası: ${response.statusCode}"); // Debug çıktısı
      print("Hata Detayı: ${response.body}"); // Hata detayını yazdır
      throw Exception('Çeviri işlemi başarısız oldu: ${response.statusCode}');
    }
  }
}
