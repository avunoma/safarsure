import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/core/widgets/common_widgets.dart';
import 'package:safarsure/features/trips/providers/trips_provider.dart';

class SearchResultsScreen extends ConsumerWidget {
  const SearchResultsScreen({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.date,
    required this.seats,
  });

  final String fromCity;
  final String toCity;
  final DateTime date;
  final int seats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);
    final dateFormat = DateFormat('EEE, d MMM');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matching trips'),
      ),
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (_) {
          final results = ref.read(tripsProvider.notifier).search(
                fromCity: fromCity,
                toCity: toCity,
                date: date,
                seatsNeeded: seats,
              );

          if (results.isEmpty) {
            return EmptyState(
              icon: Icons.search_off,
              title: 'No trips found',
              subtitle:
                  'Try a different date or route. Sample trips are available for today and the next few days.',
              action: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Modify search'),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$fromCity → $toCity',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${dateFormat.format(date)} · $seats seat${seats == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final trip = results[index];
                    return TripCard(
                      trip: trip,
                      onTap: () =>
                          context.push('/home/trip/${trip.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
