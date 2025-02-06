// lib/services/football_fixtures_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:staj_proje1/model_view/fixture_model.dart';

class FootballFixturesService {
  static const String _apiUrl =
      "https://api.collectapi.com/football/results"; // Doğru endpoint'i kullanın
  static const String _apiKey =
      "apikey 2Rd5ae3MgL0YyDdUFHGjMY:0gEEOQB4Vm0L16ispHTvBF"; // Kendi API Key'inizi ekleyin

  static Future<List<Fixture>> fetchFixtures(String leagueKey) async {
    try {
      final response = await http.get(
        Uri.parse("$_apiUrl?data.league=$leagueKey"),
        headers: {
          "authorization": _apiKey,
          "content-type": "application/json",
        },
      );

      print(
          "📢 API Response (Fixtures): ${response.body}"); // API yanıtını kontrol edin

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          List<dynamic> result = data["result"];

          return result.map((match) => Fixture.fromJson(match)).toList();
        }
      }
      throw Exception("⚠️ Fikstür verisi çekilemedi.");
    } catch (e) {
      throw Exception("❌ Hata: $e");
    }
  }
}
