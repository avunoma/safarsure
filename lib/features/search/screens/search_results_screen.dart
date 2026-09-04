import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:safarsure/core/providers/cloud_sync_provider.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/core/utils/trip_sort.dart';
import 'package:safarsure/core/widgets/common_widgets.dart';
import 'package:safarsure/data/repositories/app_repository.dart';
import 'package:safarsure/features/trips/providers/trips_provider.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.date,
    required this.seats,
    this.leavingSoonOnly = false,
  });

  final String fromCity;
  final String toCity;
  final DateTime date;
  final int seats;
  final bool leavingSoonOnly;

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  TripSortOption _sort = TripSortOption.soonest;
  bool _syncedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pullCloudTrips());
  }

  Future<void> _pullCloudTrips() async {
    final repo = await ref.read(appRepositoryProvider.future);
    if (await repo.syncTripsFromCloud()) {
      await ref.read(tripsProvider.notifier).refresh();
    }
    if (mounted) setState(() => _syncedOnce = true);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(cloudSyncPollerProvider);
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
          final filtered = ref.read(tripsProvider.notifier).search(
                fromCity: widget.fromCity,
                toCity: widget.toCity,
                date: widget.date,
                seatsNeeded: widget.seats,
                leavingSoonOnly: widget.leavingSoonOnly,
              );
          final results = sortTrips(filtered, _sort);

          if (results.isEmpty) {
            return EmptyState(
              icon: Icons.search_off,
              title: 'No trips found',
              subtitle: _syncedOnce
                  ? 'Try a different date or route. Published rides from other drivers appear here when cloud sync is on.'
                  : 'Loading trips from cloud…',
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
                      '${widget.fromCity} → ${widget.toCity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.leavingSoonOnly
                          ? 'Leaving in next 2 hours · ${widget.seats} seat${widget.seats == 1 ? '' : 's'}'
                          : '${dateFormat.format(widget.date)} · ${widget.seats} seat${widget.seats == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Wrap(
                  spacing: 8,
                  children: TripSortOption.values.map((option) {
                    return FilterChip(
                      label: Text(option.label),
                      selected: _sort == option,
                      onSelected: (_) => setState(() => _sort = option),
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _sort == option
                            ? Colors.white
                            : AppColors.charcoal,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
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
                      onTap: () => context.push('/home/trip/${trip.id}'),
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
