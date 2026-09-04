import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safarsure/core/providers/cloud_sync_provider.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/core/utils/privacy.dart';
import 'package:safarsure/core/widgets/common_widgets.dart';
import 'package:safarsure/data/models/ride_request.dart';
import 'package:safarsure/data/models/user.dart';
import 'package:safarsure/data/repositories/app_repository.dart';
import 'package:safarsure/features/auth/providers/auth_provider.dart';
import 'package:safarsure/features/trips/providers/trips_provider.dart';

class MyRidesScreen extends ConsumerWidget {
  const MyRidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isDriver = user?.role == UserRole.driver;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My rides'),
        actions: [
          if (isDriver)
            IconButton(
              onPressed: () => context.push('/my-rides/post'),
              icon: const Icon(Icons.add),
              tooltip: 'Post a ride',
            ),
        ],
      ),
      body: isDriver ? const _DriverRidesView() : const _RiderRidesView(),
      floatingActionButton: isDriver
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'join-code',
                  onPressed: () => _joinRideByCode(context, ref),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Join ride code'),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'post-ride',
                  onPressed: () => context.push('/my-rides/post'),
                  icon: const Icon(Icons.add),
                  label: const Text('Post ride'),
                ),
              ],
            )
          : null,
    );
  }
}

Future<void> _joinRideByCode(BuildContext context, WidgetRef ref) async {
  final code = await showDialog<String>(
    context: context,
    builder: (context) => const JoinRideCodeDialog(),
  );

  if (code == null || code.isEmpty || !context.mounted) return;

  final cloudReady = ref.read(cloudSyncAvailableProvider);
  if (!cloudReady) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cloud sync is off. Run with DEMO_FIREBASE_PROJECT_ID and DEMO_FIREBASE_API_KEY.',
        ),
      ),
    );
    return;
  }

  final repo = await ref.read(appRepositoryProvider.future);
  final request = await repo.importRequestBySyncCode(code);
  await ref.read(requestsProvider.notifier).refresh();

  if (!context.mounted) return;
  if (request == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ride code not found')),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Ride linked — open requests to accept')),
  );
  context.push('/my-rides/trip/${request.tripId}/requests');
}

/// Dialog with self-managed [TextEditingController] lifecycle.
class JoinRideCodeDialog extends StatefulWidget {
  const JoinRideCodeDialog({super.key});

  @override
  State<JoinRideCodeDialog> createState() => _JoinRideCodeDialogState();
}

class _JoinRideCodeDialogState extends State<JoinRideCodeDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join ride by code'),
      content: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.characters,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '6-character ride code',
          hintText: 'From rider after they request',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Join'),
        ),
      ],
    );
  }
}

class _RiderRidesView extends ConsumerWidget {
  const _RiderRidesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(cloudSyncPollerProvider);
    final requestsAsync = ref.watch(myRiderRequestsProvider);
    final repoAsync = ref.watch(appRepositoryProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (requests) {
        if (requests.isEmpty) {
          return EmptyState(
            icon: Icons.luggage_outlined,
            title: 'No rides yet',
            subtitle:
                'Search for a trip and request a seat to see your rides here.',
            action: ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Find a ride'),
            ),
          );
        }

        return repoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (repo) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final trip = repo.getTripById(request.tripId);
                if (trip == null) return const SizedBox.shrink();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => context.push(
                      '/my-rides/request/${request.id}',
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${trip.fromCity} → ${trip.toCity}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              RequestStatusChip(status: request.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            request.status == RequestStatus.confirmed
                                ? 'Driver: ${revealedFirstName(trip.driverName)} · ${request.seats} seat${request.seats == 1 ? '' : 's'}'
                                : '${privatePartyLabel(isDriver: true)} · ${request.seats} seat${request.seats == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (request.status == RequestStatus.confirmed &&
                              request.pickupPoint != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.place,
                                    size: 16, color: AppColors.success),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    request.pickupPoint!,
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
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DriverRidesView extends ConsumerWidget {
  const _DriverRidesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myDriverTripsProvider);
    final requestsAsync = ref.watch(requestsProvider);

    return tripsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (trips) {
        if (trips.isEmpty) {
          return EmptyState(
            icon: Icons.directions_car_outlined,
            title: 'No rides posted',
            subtitle: 'Post your first ride to start receiving seat requests.',
            action: ElevatedButton(
              onPressed: () => context.push('/my-rides/post'),
              child: const Text('Post a ride'),
            ),
          );
        }

        final allRequests = requestsAsync.value ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            final pendingCount = allRequests
                .where((r) =>
                    r.tripId == trip.id &&
                    r.status == RequestStatus.waiting)
                .length;

            return TripCard(
              trip: trip,
              onTap: () => context.push('/my-rides/trip/${trip.id}'),
              trailing: pendingCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$pendingCount new',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
