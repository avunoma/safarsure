import 'package:safarsure/core/services/fuel_share_calculator.dart';
import 'package:safarsure/core/services/ride_offer_limit_service.dart';
import 'package:safarsure/data/models/trip.dart';

/// Thrown when a trip fails legal-compliance validation before publish.
class TripComplianceException implements Exception {
  TripComplianceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Validates expense-share caps and ride-offer limits before publish/sync.
class TripComplianceService {
  const TripComplianceService({
    FuelShareCalculator? calculator,
    RideOfferLimitService? offerLimit,
  })  : _calculator = calculator ?? const FuelShareCalculator(),
        _offerLimit = offerLimit ?? const RideOfferLimitService();

  final FuelShareCalculator _calculator;
  final RideOfferLimitService _offerLimit;

  /// Ensures [trip] meets compliance rules before publish or cloud upsert.
  ///
  /// [isNewPublish]: when true, enforces the 24-hour ride-offer cap.
  void validateForPublish(
    Trip trip,
    List<Trip> existingTrips, {
    bool isNewPublish = true,
  }) {
    if (isNewPublish &&
        !_offerLimit.canPublish(existingTrips, trip.driverId)) {
      throw TripComplianceException(_offerLimit.limitReachedMessage());
    }

    if (trip.pricePerSeat > trip.maxFuelContributionPerSeat &&
        trip.maxFuelContributionPerSeat > 0) {
      throw TripComplianceException(
        'Fuel contribution per seat cannot exceed the calculated maximum of '
        '₹${trip.maxFuelContributionPerSeat}. This is a legal reimbursement cap '
        'based on fuel and toll costs only.',
      );
    }

    if (trip.pricePerSeat < 0) {
      throw TripComplianceException('Fuel contribution cannot be negative.');
    }
  }

  /// Recomputes max from trip fields and clamps price if needed.
  Trip normalizeTrip(Trip trip) {
    if (trip.distanceKm <= 0) {
      return trip;
    }

    final result = _calculator.calculate(
      distanceKm: trip.distanceKm,
      vehicleCategory: trip.vehicle.category,
      fuelType: trip.fuelType,
      fuelRateInr: trip.fuelRateInr,
      tollCostsInr: trip.tollCostsInr,
      passengerSeats: trip.seatsTotal,
    );

    final clampedPrice = _calculator.clampToMax(
      contributionPerSeat: trip.pricePerSeat,
      result: result,
    );

    return trip.copyWith(
      maxFuelContributionPerSeat: result.maxContributionPerSeatInr,
      pricePerSeat: clampedPrice,
    );
  }
}
