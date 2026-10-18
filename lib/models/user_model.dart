/// User Model representing the `users` table schema
class UserModel {
  final int id;
  String fullName;
  String phone;
  String email;
  String username;
  String password;
  String dateOfBirth;
  String avatar;
  String? googleId;
  String? appleId;
  String? facebookId;
  String? microsoftId;

  UserModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.username,
    required this.password,
    required this.dateOfBirth,
    required this.avatar,
    this.googleId,
    this.appleId,
    this.facebookId,
    this.microsoftId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'username': username,
      'password': password,
      'date_of_birth': dateOfBirth,
      'avatar': avatar,
      'google_id': googleId,
      'apple_id': appleId,
      'facebook_id': facebookId,
      'microsoft_id': microsoftId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id'].toString()) ?? 0,
      fullName: map['full_name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      dateOfBirth: map['date_of_birth'] ?? '',
      avatar: map['avatar'] ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      googleId: map['google_id'],
      appleId: map['apple_id'],
      facebookId: map['facebook_id'],
      microsoftId: map['microsoft_id'],
    );
  }
}
