import 'package:safarsure/data/models/vehicle.dart';

/// Legal-compliance defaults for fuel/expense share calculation.
///
/// Mileage benchmarks are typical Indian road averages (km/L or km/kWh for EV).
/// Rounding: all INR amounts round to the nearest whole rupee (half-up).
abstract final class FuelShareConstants {
  /// Default petrol rate (INR/L) when no regional override is set.
  static const double defaultPetrolInrPerLiter = 102.0;

  /// Default diesel rate (INR/L).
  static const double defaultDieselInrPerLiter = 92.0;

  /// Default EV charging rate (INR/kWh).
  static const double defaultEvInrPerKwh = 9.0;

  /// Maximum published ride offers per driver in a rolling 24-hour window.
  static const int maxRideOffersPer24Hours = 4;

  /// Typical mileage by vehicle category (km per liter of fuel).
  static const Map<VehicleCategory, double> mileageKmPerLiter = {
    VehicleCategory.hatchback: 15.0,
    VehicleCategory.sedan: 12.0,
    VehicleCategory.suv: 10.0,
  };

  /// Typical EV efficiency (km per kWh). Documented default for Indian EVs.
  static const double evKmPerKwh = 6.0;

  /// Returns the mileage benchmark for [category] and [fuelType].
  static double mileageFor({
    required VehicleCategory category,
    required FuelType fuelType,
  }) {
    if (fuelType == FuelType.ev) return evKmPerKwh;
    return mileageKmPerLiter[category] ?? mileageKmPerLiter[VehicleCategory.sedan]!;
  }
}

enum FuelType {
  petrol,
  diesel,
  ev;

  String get label => switch (this) {
        FuelType.petrol => 'Petrol',
        FuelType.diesel => 'Diesel',
        FuelType.ev => 'Electric (EV)',
      };

  String get unitLabel => switch (this) {
        FuelType.petrol => 'INR/L',
        FuelType.diesel => 'INR/L',
        FuelType.ev => 'INR/kWh',
      };
}
