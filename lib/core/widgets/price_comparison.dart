import 'package:flutter/material.dart';
import 'package:safarsure/core/pricing/fare_estimator.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/data/models/trip.dart';

/// Ola estimate vs fuel+toll cost-share comparison.
class PriceComparison extends StatelessWidget {
  const PriceComparison({
    super.key,
    required this.trip,
    this.compact = false,
  });

  final Trip trip;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final olaEstimate =
        FareEstimator.estimateOlaFare(trip.fromCity, trip.toCity);
    final share = trip.pricePerSeat;
    final savings = FareEstimator.savingsAmount(olaEstimate, share);
    final savingsPct = FareEstimator.savingsPercent(olaEstimate, share);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ola ~ ${FareEstimator.formatInr(olaEstimate)}',
                      style: TextStyle(
                        color: AppColors.charcoalMuted,
                        fontSize: compact ? 13 : 14,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.charcoalMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Estimated taxi fare',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    FareEstimator.formatInr(share),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 18 : 22,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'your share/seat',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.local_gas_station,
                  size: 14, color: AppColors.accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Fuel + toll share · share, not fare',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppColors.charcoalMuted,
                      ),
                ),
              ),
              if (savings > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Save ${FareEstimator.formatInr(savings)} ($savingsPct%)',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            Text(
              'White-plate private car · verified driver · pay only your share',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
