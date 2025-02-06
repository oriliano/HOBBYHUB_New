// lib/screens/football_top_scorers_screen.dart
import 'package:flutter/material.dart';
import '../services/football_top_scorers_service.dart';
import 'package:staj_proje1/strings/strings.dart';

class FootballTopScorersScreen extends StatefulWidget {
  final String leagueName;
  final String leagueKey;
  final String langCode;

  const FootballTopScorersScreen({
    super.key,
    required this.leagueName,
    required this.leagueKey,
    required this.langCode,
  });

  @override
  _FootballTopScorersScreenState createState() =>
      _FootballTopScorersScreenState();
}

class _FootballTopScorersScreenState extends State<FootballTopScorersScreen> {
  bool _isLoading = true;
  List<TopScorer> _filteredScorers = [];

  @override
  void initState() {
    super.initState();
    _fetchTopScorers();
  }

  Future<void> _fetchTopScorers() async {
    try {
      List<TopScorer> scorers =
          await FootballTopScorersService.fetchTopScorers(widget.leagueKey);
      setState(() {
        _filteredScorers = scorers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppStrings.getText(widget.langCode, 'errorLoadingTopScorers'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredScorers.isEmpty
              ? Center(
                  child:
                      Text(AppStrings.getText(widget.langCode, 'noTopScorers')))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _filteredScorers.length,
                  itemBuilder: (context, index) {
                    final scorer = _filteredScorers[index];
                    return Card(
                      elevation: 3.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 4.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12.0, horizontal: 16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (index + 1).toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scorer.name,
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.sports_soccer,
                                  color: Colors.orangeAccent,
                                  size: 20.0,
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  scorer.goals.toString(),
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
