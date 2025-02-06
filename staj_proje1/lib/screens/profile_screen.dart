import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:staj_proje1/model_view/profile_model.dart';
import 'package:staj_proje1/screens/edit_profile_screen.dart';
import '../services/profile_service.dart';
import '../strings/strings.dart';

class ProfileScreen extends StatefulWidget {
  final String langCode;

  const ProfileScreen({super.key, required this.langCode});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile _profile = Profile(
    name: "John Doe",
    email: "johndoe@example.com",
    bio: "This is a sample bio",
    profileImage: "",
  );

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService.loadProfile();
    setState(() {
      _profile = profile;
      if (_profile.profileImage.isNotEmpty) {
        _imageFile = File(_profile.profileImage);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _profile.profileImage = _imageFile!.path;
        });

        await ProfileService.saveProfile(_profile);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.getText(widget.langCode, 'photoUpdated')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print("❌ Resim Seçme Hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.getText(widget.langCode, 'error')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: Text(
                  AppStrings.getText(widget.langCode, 'chooseFromGallery')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera, color: Colors.blue),
              title: Text(AppStrings.getText(widget.langCode, 'takePhoto')),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    final updatedProfile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          profile: _profile,
          langCode: widget.langCode,
        ),
      ),
    );

    if (updatedProfile != null && updatedProfile is Profile) {
      setState(() {
        _profile = updatedProfile;
      });

      await ProfileService.saveProfile(updatedProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.getText(widget.langCode, 'profile')),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // İçerik ortada duracak
                  children: [
                    // **Profil Resmi**
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!) as ImageProvider
                              : _profile.profileImage.isNotEmpty
                                  ? FileImage(File(_profile.profileImage))
                                      as ImageProvider
                                  : const AssetImage(
                                      "assets/images/default_profile.png"),
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.blue, size: 30),
                          onPressed: _showImagePickerOptions,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // **İsim**
                    Text(
                      _profile.name,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),

                    // **Email**
                    Text(
                      _profile.email,
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),

                    // **Biyografi (Sınırsız Satır)**
                    Text(
                      _profile.bio,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // **Düzenleme Butonu (Her Zaman Aşağıda Ortada)**
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit, color: Colors.white),
                label: Text(AppStrings.getText(widget.langCode, 'editProfile')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _navigateToEditProfile,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
