enum VehicleCategory {
  hatchback,
  sedan,
  suv,
  ev;

  String get label => switch (this) {
        VehicleCategory.hatchback => 'Hatchback',
        VehicleCategory.sedan => 'Sedan',
        VehicleCategory.suv => 'SUV',
        VehicleCategory.ev => 'Electric (EV)',
      };
}

class Vehicle {
  const Vehicle({
    required this.make,
    required this.model,
    required this.color,
    this.category = VehicleCategory.hatchback,
  });

  final String make;
  final String model;
  final String color;
  final VehicleCategory category;

  String get displayName => '$make $model';

  Map<String, dynamic> toJson() => {
        'make': make,
        'model': model,
        'color': color,
        'category': category.name,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final categoryRaw = json['category'] as String?;
    return Vehicle(
      make: json['make'] as String,
      model: json['model'] as String,
      color: json['color'] as String,
      category: categoryRaw == null
          ? VehicleCategory.hatchback
          : VehicleCategory.values.firstWhere(
              (c) => c.name == categoryRaw,
              orElse: () => VehicleCategory.hatchback,
            ),
    );
  }

  Vehicle copyWith({
    String? make,
    String? model,
    String? color,
    VehicleCategory? category,
  }) {
    return Vehicle(
      make: make ?? this.make,
      model: model ?? this.model,
      color: color ?? this.color,
      category: category ?? this.category,
    );
  }
}
