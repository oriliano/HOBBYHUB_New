// lib/screens/football_screen.dart
import 'package:flutter/material.dart';
import 'package:staj_proje1/screens/football_leagure_detail_screen.dart';
import '../services/football_league_service.dart';
import 'package:staj_proje1/strings/strings.dart';
import 'package:staj_proje1/services/translation_service.dart';
import 'package:url_launcher/url_launcher.dart';

enum LeagueFilter { all, football, basketball, others, highlights }

class FootballScreen extends StatefulWidget {
  final String langCode;
  const FootballScreen({super.key, required this.langCode});

  @override
  State<FootballScreen> createState() => _FootballScreenState();
}

class _FootballScreenState extends State<FootballScreen> {
  List<Map<String, String>> _leagues = [];
  bool _isLoading = true;
  LeagueFilter _selectedFilter = LeagueFilter.all;

  // Manual key sets for filtering
  final Set<String> footballKeys = {
    "super-lig",
    "tff-1-lig",
    "ingiltere-premier-ligi",
    "uefa-konferans-ligi",
    "almanya-bundesliga",
    "fransa-ligue-1",
    "ispanya-la-liga",
    "italya-serie-a-ligi",
    "ingiltere-sampiyonluk-ligi",
    "almanya-bundesliga-2-ligi",
    "fransa-ligue-2",
    "/2024-uefa-euro-cup",
    "/beinsquad",
  };

  final Set<String> basketballKeys = {
    "basketbol-super-ligi",
    "euroleague",
    "nba",
  };

  final Set<String> othersKeys = {
    "/gundem/voleybol",
    "/gundem/gures",
    "/gundem/atletizm",
    "/gundem/e-spor",
    "/gundem/diger",
  };

  final Set<String> highlightsKeys = {
    "/mac-ozetleri-goller/super-lig",
    "/mac-ozetleri-goller/tff-1-lig",
    "/mac-ozetleri-goller/ingiltere-premier-ligi",
    "/mac-ozetleri-goller/almanya-bundesliga",
    "/mac-ozetleri-goller/fransa-ligue-1",
    "/mac-ozetleri-goller/almanya-bundesliga-2-ligi",
    "/mac-ozetleri-goller/fransa-ligue-2",
    "/mac-ozetleri-goller/basketbol-super-ligi",
  };

  // External URL mapping for specific keys
  final Map<String, String> _externalUrlMapping = {
    "/gundem/voleybol": "https://beinsports.com.tr/gundem/voleybol",
    "/gundem/gures": "https://beinsports.com.tr/gundem/gures",
    "/gundem/atletizm": "https://beinsports.com.tr/gundem/atletizm",
    "/gundem/e-spor": "https://beinsports.com.tr/gundem/e-spor",
    "/gundem/diger": "https://beinsports.com.tr/gundem/diger",
    "nba": "https://beinsports.com.tr/lig/nba",
    // Highlight (match summary) URLs
    "/mac-ozetleri-goller/super-lig":
        "https://beinsports.com.tr/mac-ozetleri-goller/super-lig",
    "/mac-ozetleri-goller/tff-1-lig":
        "https://beinsports.com.tr/mac-ozetleri-goller/tff-1-lig",
    "/mac-ozetleri-goller/ingiltere-premier-ligi":
        "https://beinsports.com.tr/mac-ozetleri-goller/ingiltere-premier-ligi",
    "/mac-ozetleri-goller/almanya-bundesliga":
        "https://beinsports.com.tr/mac-ozetleri-goller/almanya-bundesliga",
    "/mac-ozetleri-goller/fransa-ligue-1":
        "https://beinsports.com.tr/mac-ozetleri-goller/fransa-ligue-1",
    "/mac-ozetleri-goller/almanya-bundesliga-2-ligi":
        "https://beinsports.com.tr/mac-ozetleri-goller/almanya-bundesliga-2-ligi",
    "/mac-ozetleri-goller/fransa-ligue-2":
        "https://beinsports.com.tr/mac-ozetleri-goller/fransa-ligue-2",
    "/mac-ozetleri-goller/basketbol-super-ligi":
        "https://beinsports.com.tr/mac-ozetleri-goller/basketbol-super-ligi",
  };

  @override
  void initState() {
    super.initState();
    _fetchLeagues();
  }

  @override
  void didUpdateWidget(covariant FootballScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.langCode != widget.langCode) {
      _fetchLeagues();
    }
  }

  Future<void> _fetchLeagues() async {
    try {
      List<Map<String, String>> leagues = await FootballService.fetchLeagues();

      // If language is not Turkish, translate league names
      if (widget.langCode != 'tr') {
        leagues = await Future.wait(leagues.map((league) async {
          String originalLeague = league["league"] ?? '';
          String translatedLeague = await TranslationService.translateText(
              originalLeague, widget.langCode);
          league["league"] = translatedLeague;
          return league;
        }).toList());
      }

      setState(() {
        _leagues = leagues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppStrings.getText(widget.langCode, 'errorLoadingLeagues')),
        ),
      );
    }
  }

  // Filtered league list getter
  List<Map<String, String>> get _filteredLeagues {
    if (_selectedFilter == LeagueFilter.all) return _leagues;
    if (_selectedFilter == LeagueFilter.football) {
      return _leagues.where((league) {
        String key = (league["key"] ?? "").toLowerCase();
        return footballKeys.contains(key);
      }).toList();
    } else if (_selectedFilter == LeagueFilter.basketball) {
      return _leagues.where((league) {
        String key = (league["key"] ?? "").toLowerCase();
        return basketballKeys.contains(key);
      }).toList();
    } else if (_selectedFilter == LeagueFilter.others) {
      return _leagues.where((league) {
        String key = league["key"] ?? "";
        return othersKeys.contains(key);
      }).toList();
    } else if (_selectedFilter == LeagueFilter.highlights) {
      return _leagues.where((league) {
        String key = league["key"] ?? "";
        return highlightsKeys.contains(key);
      }).toList();
    }
    return _leagues;
  }

  // Returns an appropriate icon based on the league key
  Widget _buildLeagueIcon(String leagueKey) {
    String keyLower = leagueKey.toLowerCase();
    if (footballKeys.contains(keyLower)) {
      return const Icon(Icons.sports_soccer, color: Colors.green, size: 30);
    } else if (basketballKeys.contains(keyLower)) {
      return const Icon(Icons.sports_basketball,
          color: Colors.orange, size: 30);
    } else if (highlightsKeys.contains(leagueKey)) {
      return const Icon(Icons.video_library, color: Colors.red, size: 30);
    } else if (othersKeys.contains(leagueKey)) {
      return const Icon(Icons.sports, color: Colors.blueGrey, size: 30);
    }
    return const Icon(Icons.sports, size: 30);
  }

  // Helper method to launch an external URL
  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bağlantı açılamadı: $urlString")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.getText(widget.langCode, 'leagues')),
        actions: [
          PopupMenuButton<LeagueFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (LeagueFilter category) {
              setState(() {
                _selectedFilter = category;
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<LeagueFilter>>[
              PopupMenuItem(
                value: LeagueFilter.all,
                child: Text(widget.langCode == 'tr' ? 'Tümü' : 'All'),
              ),
              PopupMenuItem(
                value: LeagueFilter.football,
                child: Text(widget.langCode == 'tr' ? 'Futbol' : 'Football'),
              ),
              PopupMenuItem(
                value: LeagueFilter.basketball,
                child:
                    Text(widget.langCode == 'tr' ? 'Basketbol' : 'Basketball'),
              ),
              PopupMenuItem(
                value: LeagueFilter.others,
                child: Text(
                    widget.langCode == 'tr' ? 'Diğer Sporlar' : 'Other Sports'),
              ),
              PopupMenuItem(
                value: LeagueFilter.highlights,
                child: Text(widget.langCode == 'tr' ? 'Özetler' : 'Highlights'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _filteredLeagues.length,
              itemBuilder: (context, index) {
                final league = _filteredLeagues[index];
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: _buildLeagueIcon(league["key"]!),
                    title: Text(
                      league["league"]!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      String leagueKey = league["key"]!;
                      // If the league key exists in our external URL mapping, launch it; otherwise, navigate internally.
                      if (_externalUrlMapping.containsKey(leagueKey)) {
                        String? externalUrl = _externalUrlMapping[leagueKey];
                        if (externalUrl != null) {
                          _launchExternalUrl(externalUrl);
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FootballLeagueDetailScreen(
                              leagueName: league["league"]!,
                              leagueKey: leagueKey,
                              langCode: widget.langCode,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
