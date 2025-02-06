// lib/screens/football_league_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:staj_proje1/screens/football_result_screen.dart';
import 'package:staj_proje1/screens/football_standing_screen.dart';
import 'package:staj_proje1/screens/football_top_scorers_screen.dart';
import 'package:staj_proje1/strings/strings.dart';

class FootballLeagueDetailScreen extends StatefulWidget {
  final String leagueName;
  final String leagueKey;
  final String langCode;

  const FootballLeagueDetailScreen({
    super.key,
    required this.leagueName,
    required this.leagueKey,
    required this.langCode,
  });

  @override
  _FootballLeagueDetailScreenState createState() =>
      _FootballLeagueDetailScreenState();
}

class _FootballLeagueDetailScreenState extends State<FootballLeagueDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool isBasketball;

  // Manuel basketbol lig anahtarlarını içeren set (küçük harf duyarlı karşılaştırma yapabilirsiniz)
  final Set<String> basketballLeagueKeys = {
    "basketbol-super-ligi",
    "euroleague",
    "nba",
  };

  @override
  void initState() {
    super.initState();
    // Eğer widget.leagueKey (küçük harf ile) basketbol ligleri setinde varsa basketbol olarak kabul edelim.
    isBasketball =
        basketballLeagueKeys.contains(widget.leagueKey.toLowerCase());
    int tabLength = isBasketball ? 2 : 3;
    _tabController =
        TabController(length: tabLength, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sekmelerin metinlerini AppStrings üzerinden çekelim
    List<Widget> tabs = [
      Tab(text: AppStrings.getText(widget.langCode, 'standings')),
      Tab(text: AppStrings.getText(widget.langCode, 'fixtures')),
    ];
    if (!isBasketball) {
      tabs.add(Tab(text: AppStrings.getText(widget.langCode, 'topScorers')));
    }

    // TabBarView içeriği
    List<Widget> tabViews = [
      FootballStandingsScreen(
        leagueName: widget.leagueName,
        leagueKey: widget.leagueKey,
        langCode: widget.langCode,
      ),
      FootballFixturesScreen(
        leagueName: widget.leagueName,
        leagueKey: widget.leagueKey,
        langCode: widget.langCode,
      ),
    ];
    if (!isBasketball) {
      tabViews.add(FootballTopScorersScreen(
        leagueName: widget.leagueName,
        leagueKey: widget.leagueKey,
        langCode: widget.langCode,
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.leagueName),
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabViews,
      ),
    );
  }
}
