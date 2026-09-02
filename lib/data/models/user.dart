enum UserRole { rider, driver }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.rating = 4.5,
    this.role = UserRole.rider,
  });

  final String id;
  final String name;
  final String phone;
  final double rating;
  final UserRole role;

  AppUser copyWith({
    String? id,
    String? name,
    String? phone,
    double? rating,
    UserRole? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'rating': rating,
        'role': role.name,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.rider,
      ),
    );
  }
}
