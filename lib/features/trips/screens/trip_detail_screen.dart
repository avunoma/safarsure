import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/data/models/ride_request.dart';
import 'package:safarsure/data/repositories/app_repository.dart';
import 'package:safarsure/features/trips/providers/trips_provider.dart';

class TripDetailScreen extends ConsumerWidget {
  const TripDetailScreen({
    super.key,
    required this.tripId,
    this.isOwner = false,
  });

  final String tripId;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(appRepositoryProvider);
    final dateFormat = DateFormat('EEE, d MMM yyyy · h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip details'),
      ),
      body: repoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (repo) {
          final trip = repo.getTripById(tripId);
          if (trip == null) {
            return const Center(child: Text('Trip not found'));
          }

          final requestsAsync = ref.watch(tripRequestsProvider(tripId));
          final confirmedPassengers = requestsAsync.value
                  ?.where((r) => r.status == RequestStatus.confirmed)
                  .toList() ??
              [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                              foregroundColor: AppColors.primary,
                              child: Text(
                                trip.driverName[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.driverName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          size: 16, color: AppColors.accent),
                                      const SizedBox(width: 4),
                                      Text(trip.driverRating.toStringAsFixed(1)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        _DetailRow(
                          icon: Icons.trip_origin,
                          label: 'From',
                          value: trip.fromCity,
                        ),
                        if (trip.stops.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 36, top: 4),
                            child: Text(
                              'Stops: ${trip.stops.join(', ')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.location_on,
                          label: 'To',
                          value: trip.toCity,
                          iconColor: AppColors.accent,
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.schedule,
                          label: 'Departure',
                          value: dateFormat.format(trip.departureTime),
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.directions_car,
                          label: 'Car',
                          value:
                              '${trip.vehicle.make} ${trip.vehicle.model} · ${trip.vehicle.color}',
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.event_seat,
                          label: 'Seats',
                          value:
                              '${trip.seatsAvailable} of ${trip.seatsTotal} available',
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.currency_rupee,
                          label: 'Your share',
                          value: '₹${trip.pricePerSeat} per seat',
                          subtitle: 'fuel + toll share',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8ECEB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 32, color: Colors.grey),
                        SizedBox(height: 4),
                        Text('Route map placeholder',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                if (isOwner && confirmedPassengers.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Confirmed passengers',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...confirmedPassengers.map(
                    (r) => ListTile(
                      leading: CircleAvatar(
                        child: Text(r.riderName[0].toUpperCase()),
                      ),
                      title: Text(r.riderName),
                      subtitle: Text('${r.seats} seat${r.seats == 1 ? '' : 's'}'),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE8ECEB)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (isOwner) ...[
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/my-rides/trip/$tripId/requests'),
                    icon: const Icon(Icons.inbox),
                    label: const Text('View seat requests'),
                  ),
                ] else if (trip.seatsAvailable > 0) ...[
                  ElevatedButton(
                    onPressed: () =>
                        context.push('/home/trip/$tripId/request'),
                    child: const Text('Request a seat'),
                  ),
                ] else ...[
                  const OutlinedButton(
                    onPressed: null,
                    child: Text('No seats available'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppColors.charcoalMuted,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
