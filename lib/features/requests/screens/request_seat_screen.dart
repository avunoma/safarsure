import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/core/utils/privacy.dart';
import 'package:safarsure/data/repositories/app_repository.dart';
import 'package:safarsure/features/trips/providers/trips_provider.dart';

class RequestSeatScreen extends ConsumerStatefulWidget {
  const RequestSeatScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<RequestSeatScreen> createState() => _RequestSeatScreenState();
}

class _RequestSeatScreenState extends ConsumerState<RequestSeatScreen> {
  final _noteController = TextEditingController();
  int _seats = 1;
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final request = await ref.read(requestsProvider.notifier).submitRequest(
            tripId: widget.tripId,
            seats: _seats,
            note: _noteController.text.trim(),
          );

      if (mounted) {
        context.go('/my-rides/request/${request.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(appRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Request a seat')),
      body: repoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (repo) {
          final trip = repo.getTripById(widget.tripId);
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
                        const SizedBox(height: 4),
                        Text(
                          '${privatePartyLabel(isDriver: true)} · ${formatRating(trip.driverRating, trip.driverRatingCount > 0 ? trip.driverRatingCount : 12)} · ₹${trip.pricePerSeat}/seat',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<int>(
                  key: ValueKey(_seats.clamp(1, trip.seatsAvailable)),
                  initialValue: _seats.clamp(1, trip.seatsAvailable),
                  decoration: const InputDecoration(
                    labelText: 'Seats',
                    prefixIcon: Icon(Icons.event_seat),
                  ),
                  items: List.generate(
                    trip.seatsAvailable,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}'),
                    ),
                  ),
                  onChanged: (v) {
                    if (v != null) setState(() => _seats = v);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note to driver (optional)',
                    prefixIcon: Icon(Icons.note_outlined),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ₹${trip.pricePerSeat * _seats}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit request'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
