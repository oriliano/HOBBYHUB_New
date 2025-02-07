import 'dart:convert';
import 'package:http/http.dart' as http;

// Model Sınıfı
class TopScorer {
  final String name;
  final String play;
  final String goals;

  TopScorer({
    required this.name,
    required this.play,
    required this.goals,
  });

  factory TopScorer.fromJson(Map<String, dynamic> json) {
    return TopScorer(
      name: json['name']?.toString() ?? 'Bilinmiyor',
      play: json['play']?.toString() ?? '0',
      goals: json['goals']?.toString() ?? '0',
    );
  }
}

// Service Sınıfı
class FootballTopScorersService {
  static const String _apiUrl =
      "https://api.collectapi.com/football/goalKings"; // Doğru endpoint'i kullanın
  static const String _apiKey =
      " "; // Kendi API Key'inizi ekleyin

  static Future<List<TopScorer>> fetchTopScorers(String leagueKey) async {
    try {
      final response = await http.get(
        Uri.parse("$_apiUrl?data.league=$leagueKey"),
        headers: {
          "Authorization": _apiKey,
          "Content-Type": "application/json",
        },
      );

      print(
          "📢 API Response (Top Scorers): ${response.body}"); // API yanıtını kontrol edin

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          List result = data["result"];

          return result.map((player) => TopScorer.fromJson(player)).toList();
        }
      }
      throw Exception("⚠️ Gol Krallığı verisi çekilemedi.");
    } catch (e) {
      throw Exception("❌ Hata: $e");
    }
  }
}
