import 'package:safarsure/core/constants/fuel_share_constants.dart';

/// Abstraction for regional fuel/energy rates. V1 uses defaults + manual override;
/// a live API can be plugged in later via [FuelPriceService.fetchRegionalRate].
abstract class FuelPriceService {
  const FuelPriceService();

  /// Returns today's default rate for [fuelType] in the driver's region.
  ///
  /// V1: returns configured defaults. Override with [manualRateInr] when the
  /// driver confirms today's pump/charging rate at publish time.
  Future<double> fetchRegionalRate(FuelType fuelType, {String? region}) async {
    return defaultRateFor(fuelType);
  }

  /// Synchronous default when no override or API is available.
  double defaultRateFor(FuelType fuelType) => switch (fuelType) {
        FuelType.petrol => FuelShareConstants.defaultPetrolInrPerLiter,
        FuelType.diesel => FuelShareConstants.defaultDieselInrPerLiter,
        FuelType.ev => FuelShareConstants.defaultEvInrPerKwh,
      };

  /// Effective rate: driver override wins, else regional default.
  Future<double> effectiveRate(
    FuelType fuelType, {
    String? region,
    double? manualRateInr,
  }) async {
    if (manualRateInr != null && manualRateInr > 0) {
      return manualRateInr;
    }
    return fetchRegionalRate(fuelType, region: region);
  }
}

/// Default implementation using static regional defaults.
class DefaultFuelPriceService extends FuelPriceService {
  const DefaultFuelPriceService();
}
