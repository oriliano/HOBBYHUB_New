import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FootballService {
  static final String _apiUrl =
      "https://api.collectapi.com/football/leaguesList"; // ✅ API URL
  static final String _apiKey = dotenv.env['COLLECTAPI_KEY'] ?? ""; // ✅ API Key

  static Future<List<Map<String, String>>> fetchLeagues() async {
    try {
      print("⚽ Lig listesi çekiliyor...");

      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {
          "Authorization": "apikey $_apiKey",
          "Content-Type": "application/json",
        },
      );

      print("📝 API Yanıtı: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data["success"] == true && data["result"] != null) {
          List<dynamic> leagues = data["result"];

          print("✅ Ligler başarıyla çekildi: ${leagues.length} adet");

          // **JSON Verisini Parça Parça Yazdırma**
          const int chunkSize = 800; // **Parça boyutu**
          String prettyJson = jsonEncode(data);

          for (int i = 0; i < prettyJson.length; i += chunkSize) {
            print(prettyJson.substring(
                i,
                i + chunkSize > prettyJson.length
                    ? prettyJson.length
                    : i + chunkSize));
          }
          return leagues
              .map((e) => {
                    "league": e["league"].toString(), // ✅ Lig adı
                    "key": e["key"].toString() // ✅ Lig anahtar değeri
                  })
              .toList();
        } else {
          throw Exception("❌ API yanıtı beklenen formatta değil!");
        }
      } else {
        throw Exception(
            "❌ API hatası: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("🚨 Hata: $e");
      throw Exception("Hata: $e");
    }
  }
}
