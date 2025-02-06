import 'package:shared_preferences/shared_preferences.dart';
import 'package:staj_proje1/model_view/profile_model.dart';

class ProfileService {
  static const String keyName = 'profile_name';
  static const String keyEmail = 'profile_email';
  static const String keyBio = 'profile_bio';
  static const String keyProfileImage = 'profile_image';

  /// Profil Bilgilerini Kaydet
  static Future<void> saveProfile(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyName, profile.name);
    await prefs.setString(keyEmail, profile.email);
    await prefs.setString(keyBio, profile.bio);
    await prefs.setString(keyProfileImage, profile.profileImage);
  }

  /// Profil Bilgilerini Yükle
  static Future<Profile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return Profile(
      name: prefs.getString(keyName) ?? 'Kullanıcı Adı',
      email: prefs.getString(keyEmail) ?? 'email@example.com',
      bio: prefs.getString(keyBio) ?? 'Biyografiniz burada olacak',
      profileImage: prefs.getString(keyProfileImage) ??
          'assets/images/default_profile.png',
    );
  }
}
