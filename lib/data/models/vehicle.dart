class Vehicle {
  const Vehicle({
    required this.make,
    required this.model,
    required this.color,
  });

  final String make;
  final String model;
  final String color;

  String get displayName => '$make $model';

  Map<String, dynamic> toJson() => {
        'make': make,
        'model': model,
        'color': color,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      make: json['make'] as String,
      model: json['model'] as String,
      color: json['color'] as String,
    );
  }
}
