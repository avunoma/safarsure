import 'package:safarsure/core/constants/fuel_share_constants.dart';
import 'package:safarsure/data/models/trip.dart';

/// Enforces the rolling 24-hour ride-offer cap per driver (non-commercial usage).
class RideOfferLimitService {
  const RideOfferLimitService();

  /// Trips published by [driverId] within the last 24 hours.
  List<Trip> recentOffersForDriver(
    List<Trip> allTrips,
    String driverId, {
    DateTime? now,
  }) {
    final cutoff = (now ?? DateTime.now()).subtract(const Duration(hours: 24));
    return allTrips
        .where(
          (t) =>
              t.driverId == driverId &&
              !t.publishedAt.isBefore(cutoff),
        )
        .toList();
  }

  int countRecentOffers(
    List<Trip> allTrips,
    String driverId, {
    DateTime? now,
  }) =>
      recentOffersForDriver(allTrips, driverId, now: now).length;

  bool canPublish(
    List<Trip> allTrips,
    String driverId, {
    DateTime? now,
  }) =>
      countRecentOffers(allTrips, driverId, now: now) <
      FuelShareConstants.maxRideOffersPer24Hours;

  /// User-facing message when the driver has hit the cap.
  String limitReachedMessage({DateTime? now}) {
    return 'You can publish up to ${FuelShareConstants.maxRideOffersPer24Hours} '
        'ride offers in any 24-hour period. This supports non-commercial '
        'commute sharing under Motor Vehicles Act guidelines. '
        'Try again after your oldest offer is more than 24 hours old.';
  }
}
