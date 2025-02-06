import 'package:flutter/material.dart';
import 'package:staj_proje1/screens/art_screen.dart';
import 'package:staj_proje1/screens/food_screen.dart';
import 'package:staj_proje1/screens/football_league_screen.dart';
import 'package:staj_proje1/screens/navbar.dart';
import 'package:staj_proje1/screens/new_screen.dart';
import 'package:staj_proje1/screens/profile_screen.dart'; // Profil ekranı import edildi
import 'package:staj_proje1/strings/strings.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final String langCode;
  final Function(String) onLanguageChange;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.langCode,
    required this.onLanguageChange,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2; // Anasayfa sekmesi varsayılan olarak seçili

  @override
  Widget build(BuildContext context) {
    final appBarTitle = AppStrings.getText(widget.langCode, 'HobbyHub');

    final foodLabel = AppStrings.getText(widget.langCode, 'food');
    final artsLabel = AppStrings.getText(widget.langCode, 'art');
    final homeLabel = AppStrings.getText(widget.langCode, 'home');
    final footballLabel = AppStrings.getText(widget.langCode, 'sports');
    final profileLabel = AppStrings.getText(widget.langCode, 'profile');

    final pages = [
      YelpRestaurantsScreen(langCode: widget.langCode),
      ArtsScreen(langCode: widget.langCode), // Arts Screen'i ekledik
      NewsScreen(langCode: widget.langCode),
      FootballScreen(langCode: widget.langCode),
      ProfileScreen(langCode: widget.langCode), // 👈 Profil ekranı burada!
    ];

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      drawer: NavBar(
        isDarkMode: widget.isDarkMode,
        onThemeToggle: widget.onThemeToggle,
        langCode: widget.langCode,
        onLanguageChange: widget.onLanguageChange,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.food_bank), label: foodLabel),
          BottomNavigationBarItem(
              icon: const Icon(Icons.art_track), label: artsLabel),
          BottomNavigationBarItem(
              icon: const Icon(Icons.home), label: homeLabel),
          BottomNavigationBarItem(
              icon: const Icon(Icons.sports_soccer), label: footballLabel),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person), label: profileLabel),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}
