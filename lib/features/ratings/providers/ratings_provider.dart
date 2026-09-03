import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/features/auth/providers/auth_provider.dart';
import 'package:safarsure/data/repositories/app_repository.dart';

final ratingsProvider = Provider<AsyncValue<void>>((ref) {
  ref.watch(appRepositoryProvider);
  return const AsyncValue.data(null);
});

Future<void> submitTripRating(
  WidgetRef ref, {
  required String requestId,
  required String tripId,
  required String raterId,
  required String rateeId,
  required int stars,
  String comment = '',
}) async {
  final repo = await ref.read(appRepositoryProvider.future);
  await repo.submitRating(
    requestId: requestId,
    tripId: tripId,
    raterId: raterId,
    rateeId: rateeId,
    stars: stars,
    comment: comment,
  );
  ref.invalidate(ratingsProvider);
  ref.invalidate(appRepositoryProvider);
  await ref.read(authStateProvider.notifier).refreshUser();
}

final hasRatedProvider =
    Provider.family<bool, ({String requestId, String raterId})>((ref, args) {
  final repo = ref.watch(appRepositoryProvider).value;
  if (repo == null) return false;
  return repo.hasRated(args.requestId, args.raterId);
});
