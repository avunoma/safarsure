import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:safarsure/core/constants/fuel_share_constants.dart';
import 'package:safarsure/core/services/fuel_price_service.dart';
import 'package:safarsure/core/services/fuel_share_calculator.dart';
import 'package:safarsure/core/services/trip_compliance_service.dart';
import 'package:safarsure/core/theme/app_colors.dart';
import 'package:safarsure/core/utils/route_distance.dart';
import 'package:safarsure/core/widgets/place_autocomplete_field.dart';
import 'package:safarsure/data/models/trip.dart';
import 'package:safarsure/data/models/vehicle.dart';
import 'package:safarsure/data/repositories/app_repository.dart';
import 'package:safarsure/features/auth/providers/auth_provider.dart';
import 'package:safarsure/features/trips/providers/trips_provider.dart';

class PostRideScreen extends ConsumerStatefulWidget {
  const PostRideScreen({super.key});

  @override
  ConsumerState<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends ConsumerState<PostRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _distanceController = TextEditingController();
  final _tollController = TextEditingController(text: '0');
  final _fuelRateController = TextEditingController();
  final _contributionController = TextEditingController();
  final _makeController = TextEditingController(text: 'Maruti');
  final _modelController = TextEditingController(text: 'Swift');
  final _colorController = TextEditingController(text: 'White');

  final _calculator = const FuelShareCalculator();
  final _fuelPriceService = const DefaultFuelPriceService();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  int _seats = 3;
  FuelType _fuelType = FuelType.petrol;
  VehicleCategory _vehicleCategory = VehicleCategory.hatchback;
  bool _loading = false;
  bool? _canPublish;
  FuelShareResult? _computedShare;

  @override
  void initState() {
    super.initState();
    _fuelRateController.text =
        _fuelPriceService.defaultRateFor(_fuelType).toStringAsFixed(0);
    _fromController.addListener(_onRouteChanged);
    _toController.addListener(_onRouteChanged);
    _distanceController.addListener(_recalculateShare);
    _tollController.addListener(_recalculateShare);
    _fuelRateController.addListener(_recalculateShare);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPublishLimit());
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _distanceController.dispose();
    _tollController.dispose();
    _fuelRateController.dispose();
    _contributionController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _checkPublishLimit() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final repo = await ref.read(appRepositoryProvider.future);
    if (!mounted) return;
    setState(() => _canPublish = repo.canDriverPublishOffer(user.id));
  }

  void _onRouteChanged() {
    final estimated =
        estimateDistanceKm(_fromController.text, _toController.text);
    if (estimated != null && _distanceController.text.isEmpty) {
      _distanceController.text = estimated.toStringAsFixed(0);
    }
    _recalculateShare();
  }

  void _recalculateShare() {
    final distance = double.tryParse(_distanceController.text.trim());
    final tolls = double.tryParse(_tollController.text.trim()) ?? 0;
    final fuelRate = double.tryParse(_fuelRateController.text.trim());
    if (distance == null || distance <= 0 || fuelRate == null || fuelRate <= 0) {
      setState(() => _computedShare = null);
      return;
    }

    final category = _fuelType == FuelType.ev
        ? VehicleCategory.ev
        : _vehicleCategory;

    final result = _calculator.calculate(
      distanceKm: distance,
      vehicleCategory: category,
      fuelType: _fuelType,
      fuelRateInr: fuelRate,
      tollCostsInr: tolls,
      passengerSeats: _seats,
    );

    setState(() {
      _computedShare = result;
      if (_contributionController.text.isEmpty ||
          int.tryParse(_contributionController.text) == null) {
        _contributionController.text =
            result.maxContributionPerSeatInr.toString();
      }
    });
  }

  void _onFuelTypeChanged(FuelType? value) {
    if (value == null) return;
    setState(() {
      _fuelType = value;
      if (value == FuelType.ev) {
        _vehicleCategory = VehicleCategory.ev;
      }
      _fuelRateController.text =
          _fuelPriceService.defaultRateFor(value).toStringAsFixed(0);
    });
    _recalculateShare();
  }

  void _onVehicleCategoryChanged(VehicleCategory? value) {
    if (value == null) return;
    setState(() {
      _vehicleCategory = value;
      if (value == VehicleCategory.ev) {
        _fuelType = FuelType.ev;
        _fuelRateController.text = _fuelPriceService
            .defaultRateFor(FuelType.ev)
            .toStringAsFixed(0);
      }
    });
    _recalculateShare();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_computedShare == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter route distance and fuel rate to calculate share.'),
        ),
      );
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final repo = await ref.read(appRepositoryProvider.future);
    if (!repo.canDriverPublishOffer(user.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(repo.rideOfferLimitMessage())),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final departure = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final contribution = int.parse(_contributionController.text.trim());
      final category = _fuelType == FuelType.ev
          ? VehicleCategory.ev
          : _vehicleCategory;

      final trip = Trip(
        id: repo.generateId(),
        driverId: user.id,
        driverName: user.name,
        driverRating: user.rating,
        fromCity: _fromController.text.trim(),
        toCity: _toController.text.trim(),
        departureTime: departure,
        seatsTotal: _seats,
        seatsAvailable: _seats,
        pricePerSeat: contribution,
        distanceKm: double.parse(_distanceController.text.trim()),
        tollCostsInr: double.tryParse(_tollController.text.trim()) ?? 0,
        fuelType: _fuelType,
        fuelRateInr: double.parse(_fuelRateController.text.trim()),
        maxFuelContributionPerSeat: _computedShare!.maxContributionPerSeatInr,
        vehicle: Vehicle(
          make: _makeController.text.trim(),
          model: _modelController.text.trim(),
          color: _colorController.text.trim(),
          category: category,
        ),
        publishedAt: DateTime.now(),
      );

      await ref.read(tripsProvider.notifier).postTrip(trip);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride offer published successfully!')),
        );
        context.pop();
      }
    } on TripComplianceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');
    final timeFormat = DateFormat('h:mm a');
    final maxShare = _computedShare?.maxContributionPerSeatInr;

    return Scaffold(
      appBar: AppBar(title: const Text('Post a ride')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_canPublish == false)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You have reached the limit of '
                          '${FuelShareConstants.maxRideOffersPer24Hours} ride '
                          'offers in 24 hours. Try again later.',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              PlaceAutocompleteField(
                label: 'From',
                controller: _fromController,
                icon: Icons.trip_origin,
              ),
              const SizedBox(height: 16),
              PlaceAutocompleteField(
                label: 'To',
                controller: _toController,
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(dateFormat.format(_selectedDate)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(
                        timeFormat.format(
                          DateTime(2024, 1, 1, _selectedTime.hour,
                              _selectedTime.minute),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: ValueKey(_seats),
                initialValue: _seats,
                decoration: const InputDecoration(
                  labelText: 'Passenger seats offered',
                  prefixIcon: Icon(Icons.event_seat),
                ),
                items: List.generate(
                  4,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1}'),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _seats = v);
                    _recalculateShare();
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Expense share calculator',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Reimbursement is capped at fuel + toll costs only — not a fare.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.charcoalMuted,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: 'Route distance (km)',
                  prefixIcon: Icon(Icons.straighten),
                  helperText: 'Auto-filled for known routes; edit if needed',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final d = double.tryParse(v ?? '');
                  if (d == null || d <= 0) {
                    return 'Enter a valid distance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FuelType>(
                key: ValueKey(_fuelType),
                initialValue: _fuelType,
                decoration: const InputDecoration(
                  labelText: 'Fuel / energy type',
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
                items: FuelType.values
                    .map(
                      (f) => DropdownMenuItem(value: f, child: Text(f.label)),
                    )
                    .toList(),
                onChanged: _onFuelTypeChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fuelRateController,
                decoration: InputDecoration(
                  labelText: "Today's ${_fuelType.unitLabel}",
                  prefixIcon: const Icon(Icons.currency_rupee),
                  helperText: 'Confirm today\'s pump or charging rate',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final rate = double.tryParse(v ?? '');
                  if (rate == null || rate <= 0) {
                    return 'Enter a valid rate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tollController,
                decoration: const InputDecoration(
                  labelText: 'Total toll reimbursement (INR)',
                  prefixIcon: Icon(Icons.toll),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final tolls = double.tryParse(v ?? '');
                  if (tolls == null || tolls < 0) {
                    return 'Enter valid toll amount (0 if none)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_fuelType != FuelType.ev)
                DropdownButtonFormField<VehicleCategory>(
                  key: ValueKey(_vehicleCategory),
                  initialValue: _vehicleCategory,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle category',
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  items: VehicleCategory.values
                      .where((c) => c != VehicleCategory.ev)
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c, child: Text(c.label)),
                      )
                      .toList(),
                  onChanged: _onVehicleCategoryChanged,
                ),
              if (maxShare != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maximum fuel contribution per seat',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹$maxShare',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on ${_computedShare!.distanceKm.toStringAsFixed(0)} km, '
                        '${_computedShare!.mileageKmPerUnit.toStringAsFixed(1)} '
                        '${_fuelType == FuelType.ev ? 'km/kWh' : 'km/L'}, '
                        'split across ${_computedShare!.occupants} people '
                        '(driver + $_seats passenger${_seats == 1 ? '' : 's'}). '
                        'Rounded to nearest rupee.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _contributionController,
                readOnly: maxShare == null,
                decoration: InputDecoration(
                  labelText: 'Fuel contribution per seat (INR)',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  helperText: maxShare != null
                      ? 'You may lower this amount; cannot exceed ₹$maxShare'
                      : 'Calculated after entering distance and fuel rate',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final amount = int.tryParse(v ?? '');
                  if (amount == null || amount < 0) {
                    return 'Enter a valid contribution';
                  }
                  if (maxShare != null && amount > maxShare) {
                    return 'Cannot exceed maximum of ₹$maxShare';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Vehicle details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _makeController,
                decoration: const InputDecoration(labelText: 'Make'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Model'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed:
                    (_loading || _canPublish == false) ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Publish ride'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
