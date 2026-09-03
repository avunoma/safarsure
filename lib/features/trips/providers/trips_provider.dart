import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/data/models/ride_request.dart';
import 'package:safarsure/data/models/trip.dart';
import 'package:safarsure/data/repositories/app_repository.dart';
import 'package:safarsure/features/auth/providers/auth_provider.dart';

final tripsProvider =
    StateNotifierProvider<TripsNotifier, AsyncValue<List<Trip>>>((ref) {
  return TripsNotifier(ref);
});

class TripsNotifier extends StateNotifier<AsyncValue<List<Trip>>> {
  TripsNotifier(this._ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    try {
      final repo = await _ref.read(appRepositoryProvider.future);
      state = AsyncValue.data(repo.getTrips());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Trip> postTrip(Trip trip) async {
    final repo = await _ref.read(appRepositoryProvider.future);
    final created = await repo.addTrip(trip);
    await refresh();
    return created;
  }

  Future<void> updateTrip(Trip trip) async {
    final repo = await _ref.read(appRepositoryProvider.future);
    await repo.updateTrip(trip);
    await refresh();
  }

  List<Trip> search({
    required String fromCity,
    required String toCity,
    required DateTime date,
    required int seatsNeeded,
    bool leavingSoonOnly = false,
  }) {
    final repo = _ref.read(appRepositoryProvider).value;
    if (repo == null) return [];
    return repo.searchTrips(
      fromCity: fromCity,
      toCity: toCity,
      date: date,
      seatsNeeded: seatsNeeded,
      leavingSoonOnly: leavingSoonOnly,
    );
  }
}

final requestsProvider =
    StateNotifierProvider<RequestsNotifier, AsyncValue<List<RideRequest>>>(
        (ref) {
  return RequestsNotifier(ref);
});

class RequestsNotifier extends StateNotifier<AsyncValue<List<RideRequest>>> {
  RequestsNotifier(this._ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    try {
      final repo = await _ref.read(appRepositoryProvider.future);
      state = AsyncValue.data(repo.getRequests());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<RideRequest> submitRequest({
    required String tripId,
    required int seats,
    String note = '',
  }) async {
    final repo = await _ref.read(appRepositoryProvider.future);
    final user = _ref.read(authStateProvider).value;
    if (user == null) {
      throw StateError('Not logged in');
    }

    final request = RideRequest(
      id: repo.generateId(),
      tripId: tripId,
      riderId: user.id,
      riderName: user.name,
      seats: seats,
      note: note,
      createdAt: DateTime.now(),
    );

    final created = await repo.addRequest(request);
    await refresh();
    return created;
  }

  Future<void> acceptRequest(RideRequest request, Trip trip) async {
    final repo = await _ref.read(appRepositoryProvider.future);
    final pickupPoint = '${trip.fromCity} Central Pickup Point';
    final updated = request.copyWith(
      status: RequestStatus.confirmed,
      pickupPoint: pickupPoint,
      pickupTime: trip.departureTime.subtract(const Duration(minutes: 15)),
    );
    await repo.updateRequest(updated);

    final updatedTrip = trip.copyWith(
      seatsAvailable: trip.seatsAvailable - request.seats,
    );
    await repo.updateTrip(updatedTrip);

    await _ref.read(tripsProvider.notifier).refresh();
    await refresh();
  }

  Future<void> declineRequest(RideRequest request) async {
    final repo = await _ref.read(appRepositoryProvider.future);
    final updated = request.copyWith(status: RequestStatus.declined);
    await repo.updateRequest(updated);
    await refresh();
  }
}

final myRiderRequestsProvider = Provider<AsyncValue<List<RideRequest>>>((ref) {
  final requests = ref.watch(requestsProvider);
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const AsyncValue.data([]);
  return requests.whenData(
    (list) => list.where((r) => r.riderId == user.id).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(0))
          .compareTo(a.createdAt ?? DateTime(0))),
  );
});

final myDriverTripsProvider = Provider<AsyncValue<List<Trip>>>((ref) {
  final trips = ref.watch(tripsProvider);
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const AsyncValue.data([]);
  return trips.whenData(
    (list) => list.where((t) => t.driverId == user.id).toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime)),
  );
});

final tripRequestsProvider =
    Provider.family<AsyncValue<List<RideRequest>>, String>((ref, tripId) {
  final requests = ref.watch(requestsProvider);
  return requests.whenData(
    (list) => list.where((r) => r.tripId == tripId).toList(),
  );
});

final leavingSoonTripsProvider = Provider<AsyncValue<List<Trip>>>((ref) {
  final trips = ref.watch(tripsProvider);
  return trips.whenData((_) {
    final repo = ref.read(appRepositoryProvider).value;
    if (repo == null) return <Trip>[];
    return repo.getLeavingSoonTrips();
  });
});
