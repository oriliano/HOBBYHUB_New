// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:staj_proje1/screens/home_screen.dart';
import 'package:staj_proje1/services/local_provider.dart';
import 'package:staj_proje1/strings/strings.dart';
import 'package:intl/date_symbol_data_local.dart'; // intl paketini ekleyin

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter binding'ini başlatın
  await dotenv.load(fileName: ".env"); // .env dosyasını yükleyin
  print("DotEnv Yüklendi: ${dotenv.env}"); // Debug çıktısı
  await initializeDateFormatting('tr_TR', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _currentLangCode = 'tr'; // Varsayılan dil kodu
  bool _isDarkMode = false; // Tema durumu

  void _changeLanguage(String newLangCode) {
    setState(() {
      _currentLangCode = newLangCode;
      print("Dil değiştirildi: $_currentLangCode"); // Debug çıktısı
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      print("Tema değiştirildi: $_isDarkMode"); // Debug çıktısı
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.getText(_currentLangCode, 'twitterLikeApp'),
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomeScreen(
        langCode: _currentLangCode,
        onLanguageChange: _changeLanguage,
        isDarkMode: _isDarkMode,
        onThemeToggle: _toggleTheme,
      ),
    );
  }
}
