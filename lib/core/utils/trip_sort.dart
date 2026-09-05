import 'package:safarsure/data/models/trip.dart';

enum TripSortOption {
  soonest,
  lowestContribution,
  highestRating,
}

extension TripSortOptionLabel on TripSortOption {
  String get label => switch (this) {
        TripSortOption.soonest => 'Soonest',
        TripSortOption.lowestContribution => 'Lowest contribution',
        TripSortOption.highestRating => 'Highest rating',
      };
}

List<Trip> sortTrips(List<Trip> trips, TripSortOption sort) {
  final sorted = List<Trip>.from(trips);
  switch (sort) {
    case TripSortOption.soonest:
      sorted.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    case TripSortOption.lowestContribution:
      sorted.sort((a, b) {
        final price = a.pricePerSeat.compareTo(b.pricePerSeat);
        return price != 0 ? price : a.departureTime.compareTo(b.departureTime);
      });
    case TripSortOption.highestRating:
      sorted.sort((a, b) {
        final rating = b.driverRating.compareTo(a.driverRating);
        return rating != 0 ? rating : a.departureTime.compareTo(b.departureTime);
      });
  }
  return sorted;
}
