// lib/screens/football_fixtures_screen.dart
import 'package:flutter/material.dart';
import 'package:staj_proje1/model_view/fixture_model.dart';
import 'package:staj_proje1/services/football_result_service.dart';
import 'package:staj_proje1/services/translation_service.dart';
import 'package:intl/intl.dart'; // intl paketini ekleyin
import 'package:staj_proje1/strings/strings.dart'; // Lokalizasyon için

class FootballFixturesScreen extends StatefulWidget {
  final String leagueName;
  final String leagueKey;
  final String langCode; // Dil ayarı

  const FootballFixturesScreen({
    super.key,
    required this.leagueName,
    required this.leagueKey,
    required this.langCode,
  });

  @override
  _FootballFixturesScreenState createState() => _FootballFixturesScreenState();
}

class _FootballFixturesScreenState extends State<FootballFixturesScreen> {
  List<Fixture> _fixtures = [];
  bool _isLoading = true;
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchFixtures();
  }

  Future<void> _fetchFixtures() async {
    try {
      // API'den fixture verilerini çekiyoruz
      List<Fixture> fixtures =
          await FootballFixturesService.fetchFixtures(widget.leagueKey);

      // Eğer dil Türkçe değilse, fixture'daki takım isimlerini çeviriyoruz.
      if (widget.langCode != 'tr') {
        fixtures = await Future.wait(fixtures.map((fixture) async {
          String translatedHome = await TranslationService.translateText(
              fixture.home, widget.langCode);
          String translatedAway = await TranslationService.translateText(
              fixture.away, widget.langCode);
          // İsteğe bağlı olarak diğer alanlar da çevirilebilir.
          return Fixture(
            date: fixture.date,
            home: translatedHome,
            away: translatedAway,
            score: fixture.score,
          );
        }).toList());
      }

      setState(() {
        _fixtures = fixtures;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fikstürü yüklerken hata oluştu: $e")),
      );
    }
  }

  // Maçları tarihe göre gruplandırmak için yardımcı metod
  Map<String, List<Fixture>> _groupFixturesByDate(List<Fixture> fixtures) {
    Map<String, List<Fixture>> grouped = {};
    for (var fixture in fixtures) {
      try {
        DateTime parsedDate = DateTime.parse(fixture.date);
        String dateKey = DateFormat('yyyy-MM-dd').format(parsedDate);
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(fixture);
      } catch (e) {
        print("⚠️ Tarih parse hatası: ${fixture.date} -> $e");
      }
    }
    return grouped;
  }

  // Arama sorgusuna göre filtreleme
  List<Fixture> _filterFixtures(List<Fixture> fixtures, String query) {
    if (query.isEmpty) return fixtures;
    return fixtures.where((fixture) {
      final home = fixture.home.toLowerCase();
      final away = fixture.away.toLowerCase();
      final searchLower = query.toLowerCase();
      return home.contains(searchLower) || away.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Arama sonucuna göre fixture'ları filtrele
    List<Fixture> filteredFixtures = _filterFixtures(_fixtures, _searchQuery);
    // Fixture'ları tarihe göre grupla
    Map<String, List<Fixture>> groupedFixtures =
        _groupFixturesByDate(filteredFixtures);
    List<String> sortedDates = groupedFixtures.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    // Temadan renkleri alıyoruz
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final subtitleColor = theme.textTheme.titleMedium?.color ?? Colors.grey;
    final cardColor = theme.cardColor;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredFixtures.isEmpty
              ? Center(
                  child:
                      Text(AppStrings.getText(widget.langCode, 'noFixtures')))
              : ListView.builder(
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    String date = sortedDates[index];
                    List<Fixture> fixturesForDate = groupedFixtures[date]!;

                    // Tarihi okunabilir formata çeviriyoruz
                    DateTime parsedDate = DateTime.parse(date);
                    String formattedDate = DateFormat('EEEE, d MMMM yyyy',
                            widget.langCode == 'tr' ? 'tr_TR' : 'en_US')
                        .format(parsedDate);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarih Başlığı
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                          child: Text(
                            formattedDate,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Her tarih için fixture listesini gösteriyoruz
                        ...fixturesForDate.map((fixture) {
                          // API tarih stringinden saat bilgisini doğrudan alıyoruz
                          // Bu yöntem, Dart'ın UTC dönüşümü yapmasını önler.
                          String formattedTime = fixture.date.substring(11, 16);
                          bool isPlayed = fixture.score != "Skor Yok" &&
                              fixture.score != "undefined-undefined";

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 4.0),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.black54
                                        : Colors.grey.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Maç Saati ve Durumu
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formattedTime,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: subtitleColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Icon(
                                        isPlayed
                                            ? Icons.check_circle
                                            : Icons.schedule,
                                        color: isPlayed
                                            ? Colors.green
                                            : Colors.orangeAccent,
                                        size: 20.0,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8.0),
                                  // Takım Bilgileri (Home, Skor/VS, Away)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          fixture.home,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isPlayed
                                                ? textColor
                                                : subtitleColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        isPlayed ? fixture.score : 'VS',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isPlayed
                                              ? Colors.blue
                                              : subtitleColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                      Expanded(
                                        child: Text(
                                          fixture.away,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isPlayed
                                                ? textColor
                                                : subtitleColor,
                                          ),
                                          textAlign: TextAlign.right,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8.0),
                                  // Maç Durumu (Eğer oynanmadıysa)
                                  if (!isPlayed)
                                    Text(
                                      AppStrings.getText(
                                          widget.langCode, 'matchNotPlayed'),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
    );
  }
}
