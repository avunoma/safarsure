import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/core/widgets/common_widgets.dart';
import 'package:safarsure/data/models/user.dart';
import 'package:safarsure/features/auth/providers/auth_provider.dart';
import 'package:safarsure/features/trips/providers/trips_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isDriver = user?.role == UserRole.driver;
    final leavingSoonAsync = ref.watch(leavingSoonTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafarSure'),
        actions: [
          if (isDriver)
            TextButton.icon(
              onPressed: () => context.push('/my-rides/post'),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Post ride',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.name ?? 'Traveller'} 👋',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              isDriver
                  ? 'Manage your rides or switch to Rider mode in Profile.'
                  : 'Share a ride — pay fuel + toll, not a taxi fare.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.charcoalMuted,
                  ),
            ),
            const SizedBox(height: 28),
            if (!isDriver) ...[
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => context.push('/home/search'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8ECEB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.search,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Where to?',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Search intercity carpools across India',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.charcoalMuted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _ShareNotFareBanner(),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.accent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Leaving soon',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Next 2 hrs',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Trips departing in the next 2 hours',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              leavingSoonAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text('Could not load trips: $e'),
                data: (trips) {
                  if (trips.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No trips in the next 2 hours right now.'),
                    );
                  }
                  return Column(
                    children: trips
                        .map(
                          (trip) => TripCard(
                            trip: trip,
                            onTap: () =>
                                context.push('/home/trip/${trip.id}'),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Popular routes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _RouteChip(
                label: 'Bengaluru → Chennai',
                onTap: () => context.push('/home/search'),
              ),
              _RouteChip(
                label: 'Mumbai → Pune',
                onTap: () => context.push('/home/search'),
              ),
              _RouteChip(
                label: 'Delhi → Jaipur',
                onTap: () => context.push('/home/search'),
              ),
            ] else ...[
              _DriverHomeCard(
                onPostRide: () => context.push('/my-rides/post'),
                onViewRides: () => context.go('/my-rides'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShareNotFareBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Share, not fare',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Verified private car · pay only fuel + toll share',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteChip extends StatelessWidget {
  const _RouteChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ActionChip(
        label: Text(label),
        avatar: const Icon(Icons.route, size: 18, color: AppColors.primary),
        onPressed: onTap,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE8ECEB)),
      ),
    );
  }
}

class _DriverHomeCard extends StatelessWidget {
  const _DriverHomeCard({
    required this.onPostRide,
    required this.onViewRides,
  });

  final VoidCallback onPostRide;
  final VoidCallback onViewRides;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.directions_car,
                size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'Driver mode',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Post a new ride or manage incoming seat requests.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.charcoalMuted,
                  ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPostRide,
              child: const Text('Post a ride'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onViewRides,
              child: const Text('View my rides'),
            ),
          ],
        ),
      ),
    );
  }
}
