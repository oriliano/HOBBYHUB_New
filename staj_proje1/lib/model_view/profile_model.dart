class Profile {
  String name;
  String email;
  String bio;
  String profileImage;

  Profile({
    required this.name,
    required this.email,
    required this.bio,
    required this.profileImage,
  });

  Map<String, String> toMap() {
    return {
      'name': name,
      'email': email,
      'bio': bio,
      'profileImage': profileImage,
    };
  }

  factory Profile.fromMap(Map<String, String> map) {
    return Profile(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      profileImage: map['profileImage'] ?? '',
    );
  }
}
