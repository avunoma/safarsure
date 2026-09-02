import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/core/widgets/common_widgets.dart';
import 'package:safarsure/data/models/ride_request.dart';
import 'package:safarsure/data/repositories/app_repository.dart';

class RequestStatusScreen extends ConsumerWidget {
  const RequestStatusScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repoAsync = ref.watch(appRepositoryProvider);
    final dateFormat = DateFormat('EEE, d MMM · h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Request status')),
      body: repoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (repo) {
          final request = repo.getRequestById(requestId);
          if (request == null) {
            return const Center(child: Text('Request not found'));
          }

          final trip = repo.getTripById(request.tripId);
          if (trip == null) {
            return const Center(child: Text('Trip not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _StatusIcon(status: request.status),
                        const SizedBox(height: 16),
                        RequestStatusChip(status: request.status),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage(request.status),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip.fromCity} → ${trip.toCity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.person,
                          label: 'Driver',
                          value: trip.driverName,
                        ),
                        _InfoRow(
                          icon: Icons.event_seat,
                          label: 'Seats',
                          value: '${request.seats}',
                        ),
                        _InfoRow(
                          icon: Icons.currency_rupee,
                          label: 'Total',
                          value: '₹${trip.pricePerSeat * request.seats}',
                        ),
                        if (request.note.isNotEmpty)
                          _InfoRow(
                            icon: Icons.note,
                            label: 'Your note',
                            value: request.note,
                          ),
                      ],
                    ),
                  ),
                ),
                if (request.status == RequestStatus.confirmed) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: AppColors.success.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppColors.success),
                              SizedBox(width: 8),
                              Text(
                                'Pickup details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (request.pickupPoint != null)
                            _InfoRow(
                              icon: Icons.place,
                              label: 'Pickup point',
                              value: request.pickupPoint!,
                            ),
                          if (request.pickupTime != null)
                            _InfoRow(
                              icon: Icons.schedule,
                              label: 'Pickup time',
                              value: dateFormat.format(request.pickupTime!),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (request.status == RequestStatus.declined) ...[
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'This request was declined by the driver. Try searching for another trip.',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusMessage(RequestStatus status) {
    return switch (status) {
      RequestStatus.waiting =>
        'Your request has been sent. Waiting for the driver to respond.',
      RequestStatus.confirmed =>
        'Your seat is confirmed! Check pickup details below.',
      RequestStatus.declined =>
        'Unfortunately, the driver declined your request.',
    };
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      RequestStatus.waiting => (Icons.hourglass_top, AppColors.accent),
      RequestStatus.confirmed => (Icons.check_circle, AppColors.success),
      RequestStatus.declined => (Icons.cancel, AppColors.error),
    };

    return Icon(icon, size: 64, color: color);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.charcoalMuted),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
