import 'dart:math';

import 'package:safarsure/core/constants/fuel_share_constants.dart';
import 'package:safarsure/data/models/vehicle.dart';

/// Result of the fuel/expense share calculation for a trip.
class FuelShareResult {
  const FuelShareResult({
    required this.totalRouteCostInr,
    required this.maxContributionPerSeatInr,
    required this.fuelCostInr,
    required this.tollCostsInr,
    required this.distanceKm,
    required this.fuelRateInr,
    required this.mileageKmPerUnit,
    required this.occupants,
  });

  /// Total reimbursable route cost (fuel + tolls), before splitting.
  final double totalRouteCostInr;

  /// Maximum permissible expense share per passenger seat (strict cap).
  final int maxContributionPerSeatInr;

  final double fuelCostInr;
  final double tollCostsInr;
  final double distanceKm;
  final double fuelRateInr;
  final double mileageKmPerUnit;

  /// Passengers + driver (denominator for cost split).
  final int occupants;
}

/// Computes maximum permissible cost-share per passenger from fuel + tolls only.
///
/// Formula:
///   Total Route Cost = (Distance_km / Mileage) * Fuel_Rate + Toll_Costs
///   Cost Per Person  = Total Route Cost / (Passengers + 1 Driver)
///
/// Rounding: nearest whole INR (half-up) via [roundInr].
class FuelShareCalculator {
  const FuelShareCalculator();

  /// Rounds [amount] to the nearest rupee (half-up). Documented rounding rule.
  static int roundInr(double amount) => amount.round();

  FuelShareResult calculate({
    required double distanceKm,
    required VehicleCategory vehicleCategory,
    required FuelType fuelType,
    required double fuelRateInr,
    required double tollCostsInr,
    required int passengerSeats,
  }) {
    assert(distanceKm >= 0, 'distance must be non-negative');
    assert(passengerSeats >= 1, 'at least one passenger seat');
    assert(fuelRateInr > 0, 'fuel rate must be positive');
    assert(tollCostsInr >= 0, 'tolls must be non-negative');

    final mileage = FuelShareConstants.mileageFor(
      category: vehicleCategory,
      fuelType: fuelType,
    );

    final fuelCost = (distanceKm / mileage) * fuelRateInr;
    final totalRouteCost = fuelCost + tollCostsInr;
    final occupants = passengerSeats + 1; // passengers + driver
    final costPerPerson = totalRouteCost / occupants;

    return FuelShareResult(
      totalRouteCostInr: totalRouteCost,
      maxContributionPerSeatInr: roundInr(costPerPerson),
      fuelCostInr: fuelCost,
      tollCostsInr: tollCostsInr,
      distanceKm: distanceKm,
      fuelRateInr: fuelRateInr,
      mileageKmPerUnit: mileage,
      occupants: occupants,
    );
  }

  /// Returns true if [contributionPerSeat] is at or below the computed maximum.
  bool isWithinCap({
    required int contributionPerSeat,
    required FuelShareResult result,
  }) =>
      contributionPerSeat <= result.maxContributionPerSeatInr;

  /// Clamps [contributionPerSeat] to the legal maximum (never above max).
  int clampToMax({
    required int contributionPerSeat,
    required FuelShareResult result,
  }) =>
      min(contributionPerSeat, result.maxContributionPerSeatInr);
}
