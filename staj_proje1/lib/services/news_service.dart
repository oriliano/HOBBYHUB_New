// lib/services/news_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model_view/news_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsService {
  static final String apiKey = dotenv.env['COLLECTAPI_KEY'] ??
      'YOUR_COLLECTAPI_KEY'; // API anahtarınızı buraya ekleyin

  // Haberleri çeker
  static Future<List<NewsItem>> fetchNews(String langCode, int page) async {
    final countryParam =
        'tr'; // Kaynakların her zaman Türkçe olması için 'tr' kullanıyoruz
    final limit = 10; // Her sayfada çekilecek haber sayısı
    final offset = (page - 1) * limit;

    final url = Uri.parse(
      'https://api.collectapi.com/news/getNews?country=$countryParam&tag=general&offset=$offset&limit=$limit',
    );

    final response = await http.get(
      url,
      headers: {
        'authorization': apiKey,
        'content-type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final List<dynamic> resultList = jsonBody['result'] ?? [];
      print("Haber servisi: $resultList"); // Debug çıktısı
      return resultList.map((e) => NewsItem.fromJson(e)).toList();
    } else {
      print("Haber servisi hatası: ${response.statusCode}"); // Debug çıktısı
      print("Hata Detayı: ${response.body}"); // Hata detayını yazdır
      throw Exception('Haberleri çekerken hata oluştu: ${response.statusCode}');
    }
  }
}
