// lib/models/fixture.dart
class Fixture {
  final String date;
  final String home;
  final String away;
  final String score;

  Fixture({
    required this.date,
    required this.home,
    required this.away,
    required this.score,
  });

  factory Fixture.fromJson(Map<String, dynamic> json) {
    return Fixture(
      date: json['date']?.toString() ?? 'Tarih Bilinmiyor',
      home: json['home']?.toString() ?? 'Bilinmiyor',
      away: json['away']?.toString() ?? 'Bilinmiyor',
      score: json['skor']?.toString() ?? 'Skor Yok',
    );
  }
}
