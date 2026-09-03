enum UserRole { rider, driver }

enum AuthMethod { demo, phone, google }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    this.phone = '',
    this.email,
    this.photoUrl,
    this.rating = 4.5,
    this.ratingCount = 0,
    this.role = UserRole.rider,
    this.authMethod = AuthMethod.demo,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? photoUrl;
  final double rating;
  final int ratingCount;
  final UserRole role;
  final AuthMethod authMethod;

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Traveller';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? photoUrl,
    double? rating,
    int? ratingCount,
    UserRole? role,
    AuthMethod? authMethod,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      role: role ?? this.role,
      authMethod: authMethod ?? this.authMethod,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'photoUrl': photoUrl,
        'rating': rating,
        'ratingCount': ratingCount,
        'role': role.name,
        'authMethod': authMethod.name,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      ratingCount: json['ratingCount'] as int? ?? 0,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.rider,
      ),
      authMethod: AuthMethod.values.firstWhere(
        (m) => m.name == json['authMethod'],
        orElse: () => AuthMethod.demo,
      ),
    );
  }
}
