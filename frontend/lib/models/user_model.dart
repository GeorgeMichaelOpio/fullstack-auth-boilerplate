/// Typed user model.
///
/// Passing a raw `Map<String, dynamic>` between screens (as the original
/// code did) means every field access can silently fail or throw at
/// runtime, with no compile-time safety and no single place documenting
/// what the server actually returns. A model class fixes that, and gives
/// us one place to change parsing logic if the API shape changes.
///
/// Note: intentionally does NOT include an IP address field. A user's IP
/// is not something to display back to them in a profile UI - it's not
/// meaningful to them, it's a privacy-sensitive value, and if you need it
/// for security/fraud purposes it belongs in server-side logs, not a
/// client-rendered widget.
class UserModel {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? birthdate;
  final String? gender;
  final String? city;
  final String? profilePictureUrl;
  final String? phone;
  final DateTime? joinedAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.birthdate,
    this.gender,
    this.city,
    this.profilePictureUrl,
    this.phone,
    this.joinedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      birthdate: json['birthdate']?.toString(),
      gender: json['gender']?.toString(),
      city: json['location']?.toString(),
      profilePictureUrl: json['profile_picture']?.toString(),
      phone: json['phone']?.toString(),
      joinedAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}
