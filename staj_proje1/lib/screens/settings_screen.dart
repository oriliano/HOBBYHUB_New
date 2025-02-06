// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:staj_proje1/strings/strings.dart';

class SettingsScreen extends StatelessWidget {
  final String langCode;
  final Function(String) onLanguageChange;

  const SettingsScreen({
    super.key,
    required this.langCode,
    required this.onLanguageChange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.getText(langCode, 'languageSettings')),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(AppStrings.getText(langCode, 'turkish')),
            trailing:
                langCode == 'tr' ? Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              onLanguageChange('tr');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(AppStrings.getText(langCode, 'english')),
            trailing:
                langCode == 'en' ? Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              onLanguageChange('en');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
