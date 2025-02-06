import 'dart:io';
import 'package:flutter/material.dart';
import 'package:staj_proje1/screens/settings_screen.dart';
import 'package:staj_proje1/strings/strings.dart';
import 'package:staj_proje1/services/profile_service.dart';
import 'package:staj_proje1/model_view/profile_model.dart';

class NavBar extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  final String langCode;
  final Function(String) onLanguageChange;

  const NavBar({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.langCode,
    required this.onLanguageChange,
  });

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  Profile _profile = Profile(
    name: "Guest",
    email: "guest@example.com",
    bio: "Welcome!",
    profileImage: "",
  );

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// **Profil verilerini yükleme**
  Future<void> _loadProfile() async {
    final profile = await ProfileService.loadProfile();
    setState(() {
      _profile = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsText = AppStrings.getText(widget.langCode, 'settings');

    return Drawer(
      child: ListView(
        children: [
          // **Profil Bilgileri (Fotoğraf + İsim + E-posta)**
          DrawerHeader(
            decoration: BoxDecoration(
              color: widget.isDarkMode ? Colors.black87 : Colors.blue,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: _profile.profileImage.isNotEmpty
                      ? FileImage(File(_profile.profileImage)) as ImageProvider
                      : const AssetImage("assets/images/default_profile.png"),
                ),
                const SizedBox(height: 8),
                Text(
                  _profile.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  _profile.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // **Tema Değiştirme**
          ListTile(
            leading: Icon(
              widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: widget.isDarkMode ? Colors.yellow : Colors.blue,
            ),
            title: Text(
              AppStrings.getText(widget.langCode, 'theme'),
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            trailing: Switch(
              value: widget.isDarkMode,
              onChanged: (bool value) {
                widget.onThemeToggle();
              },
              activeColor: Colors.yellow,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey[300],
            ),
          ),

          // **Ayarlar Butonu**
          ListTile(
            leading: Icon(
              Icons.settings,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
            title: Text(
              settingsText,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    langCode: widget.langCode,
                    onLanguageChange: widget.onLanguageChange,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
