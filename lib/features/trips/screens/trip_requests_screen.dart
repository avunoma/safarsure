import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/core/widgets/common_widgets.dart';
import 'package:safarsure/data/models/ride_request.dart';
import 'package:safarsure/data/repositories/app_repository.dart';
import 'package:safarsure/features/trips/providers/trips_provider.dart';

class TripRequestsScreen extends ConsumerWidget {
  const TripRequestsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(tripRequestsProvider(tripId));
    final repoAsync = ref.watch(appRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seat requests')),
      body: repoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (repo) {
          final trip = repo.getTripById(tripId);
          if (trip == null) {
            return const Center(child: Text('Trip not found'));
          }

          return requestsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (requests) {
              if (requests.isEmpty) {
                return const EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'No requests yet',
                  subtitle:
                      'When riders request seats on this trip, they will appear here.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary
                                    .withValues(alpha: 0.15),
                                foregroundColor: AppColors.primary,
                                child: Text(
                                  request.riderName[0].toUpperCase(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.riderName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${request.seats} seat${request.seats == 1 ? '' : 's'}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              RequestStatusChip(status: request.status),
                            ],
                          ),
                          if (request.note.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '"${request.note}"',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          if (request.status == RequestStatus.waiting) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => ref
                                        .read(requestsProvider.notifier)
                                        .declineRequest(request),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      side: const BorderSide(
                                          color: AppColors.error),
                                      minimumSize: const Size(0, 44),
                                    ),
                                    child: const Text('Decline'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => ref
                                        .read(requestsProvider.notifier)
                                        .acceptRequest(request, trip),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(0, 44),
                                    ),
                                    child: const Text('Accept'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (request.status == RequestStatus.confirmed &&
                              request.pickupPoint != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.place,
                                    size: 16, color: AppColors.success),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Pickup: ${request.pickupPoint}',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
