// lib/screens/football_standing_screen.dart
import 'package:flutter/material.dart';
import 'package:staj_proje1/services/football_standing_service';
import 'package:staj_proje1/strings/strings.dart';

class FootballStandingsScreen extends StatefulWidget {
  final String leagueName;
  final String leagueKey;
  final String langCode;

  const FootballStandingsScreen({
    super.key,
    required this.leagueName,
    required this.leagueKey,
    required this.langCode,
  });

  @override
  _FootballStandingsScreenState createState() =>
      _FootballStandingsScreenState();
}

class _FootballStandingsScreenState extends State<FootballStandingsScreen> {
  List<Standings> _standings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStandings();
  }

  Future<void> _fetchStandings() async {
    try {
      List<Standings> standings =
          await FootballStandingsService.fetchStandings(widget.leagueKey);
      setState(() {
        _standings = standings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppStrings.getText(widget.langCode, 'errorLoadingStandings')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _standings.isEmpty
              ? Center(
                  child:
                      Text(AppStrings.getText(widget.langCode, 'noStandings')),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      // Tablo Başlığı
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 35,
                              alignment: Alignment.center,
                              child: Text(
                                AppStrings.getText(widget.langCode, 'rank'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 3,
                              child: Text(
                                AppStrings.getText(widget.langCode, 'team'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                AppStrings.getText(widget.langCode, 'played'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                AppStrings.getText(widget.langCode, 'won'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                AppStrings.getText(widget.langCode, 'lost'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                AppStrings.getText(widget.langCode, 'points'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _standings.length,
                          itemBuilder: (context, index) {
                            final team = _standings[index];
                            return Card(
                              elevation: 2.0,
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: [
                                    // Rank: sabit genişlikte konteyner
                                    Container(
                                      width: 30,
                                      alignment: Alignment.center,
                                      child: Text(
                                        team.rank,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Takım adı: sol hizalı
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        team.team,
                                        textAlign: TextAlign.left,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    // Oynadı
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        team.play,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    // Kazandı
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        team.win,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    // Kaybetti
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        team.lose,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    // Puan
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        team.point,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
