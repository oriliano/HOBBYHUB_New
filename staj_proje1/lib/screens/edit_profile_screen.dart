import 'package:flutter/material.dart';
import 'package:staj_proje1/model_view/profile_model.dart';
import '../services/profile_service.dart';
import '../strings/strings.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;
  final String langCode;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.langCode,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _emailController = TextEditingController(text: widget.profile.email);
    _bioController = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// **Profil bilgilerini kaydetme**
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = Profile(
        name: _nameController.text,
        email: _emailController.text,
        bio: _bioController.text,
        profileImage: widget.profile.profileImage, // Fotoğraf değişmiyor
      );

      await ProfileService.saveProfile(updatedProfile);
      Navigator.pop(context, updatedProfile);

      // **Başarı mesajı göster**
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.getText(widget.langCode, 'profileUpdated')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.getText(widget.langCode, 'editProfile')),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        elevation: 0,
      ),
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],

      // **Sayfanın Scroll Edilebilmesi İçin** 👇
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // **İsim Alanı**
                Text(
                  AppStrings.getText(widget.langCode, 'name'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.getText(
                          widget.langCode, 'requiredField');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // **E-posta Alanı**
                Text(
                  AppStrings.getText(widget.langCode, 'email'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.getText(
                          widget.langCode, 'requiredField');
                    } else if (!RegExp(
                            r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$')
                        .hasMatch(value)) {
                      return AppStrings.getText(
                          widget.langCode, 'invalidEmail');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // **Biyografi Alanı**
                Text(
                  AppStrings.getText(widget.langCode, 'bio'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.getText(
                          widget.langCode, 'requiredField');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),

                // **Kaydet Butonu**
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDarkMode ? Colors.grey[800] : Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppStrings.getText(widget.langCode, 'save'),
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
