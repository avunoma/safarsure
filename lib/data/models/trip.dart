import 'package:safarsure/core/constants/fuel_share_constants.dart';
import 'package:safarsure/data/models/vehicle.dart';

class Trip {
  const Trip({
    required this.id,
    required this.driverId,
    required this.fromCity,
    required this.toCity,
    required this.departureTime,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.pricePerSeat,
    required this.vehicle,
    this.stops = const [],
    this.driverName = '',
    this.driverRating = 4.5,
    this.driverRatingCount = 0,
    this.distanceKm = 0,
    this.tollCostsInr = 0,
    this.fuelType = FuelType.petrol,
    this.fuelRateInr = FuelShareConstants.defaultPetrolInrPerLiter,
    this.maxFuelContributionPerSeat = 0,
    DateTime? publishedAt,
  }) : publishedAt = publishedAt ?? departureTime;

  final String id;
  final String driverId;
  final String fromCity;
  final String toCity;
  final DateTime departureTime;
  final int seatsTotal;
  final int seatsAvailable;

  /// Per-seat fuel contribution / expense share (INR). Not a commercial fare.
  final int pricePerSeat;
  final Vehicle vehicle;
  final List<String> stops;
  final String driverName;
  final double driverRating;
  final int driverRatingCount;

  /// Route distance used for reimbursement calculation (km).
  final double distanceKm;

  /// Total toll reimbursement for the route (INR).
  final double tollCostsInr;
  final FuelType fuelType;
  final double fuelRateInr;

  /// Computed legal maximum per seat at publish time.
  final int maxFuelContributionPerSeat;

  /// When the driver published this offer (for 24h ride-offer cap).
  final DateTime publishedAt;

  Trip copyWith({
    String? id,
    String? driverId,
    String? fromCity,
    String? toCity,
    DateTime? departureTime,
    int? seatsTotal,
    int? seatsAvailable,
    int? pricePerSeat,
    Vehicle? vehicle,
    List<String>? stops,
    String? driverName,
    double? driverRating,
    int? driverRatingCount,
    double? distanceKm,
    double? tollCostsInr,
    FuelType? fuelType,
    double? fuelRateInr,
    int? maxFuelContributionPerSeat,
    DateTime? publishedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      departureTime: departureTime ?? this.departureTime,
      seatsTotal: seatsTotal ?? this.seatsTotal,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      vehicle: vehicle ?? this.vehicle,
      stops: stops ?? this.stops,
      driverName: driverName ?? this.driverName,
      driverRating: driverRating ?? this.driverRating,
      driverRatingCount: driverRatingCount ?? this.driverRatingCount,
      distanceKm: distanceKm ?? this.distanceKm,
      tollCostsInr: tollCostsInr ?? this.tollCostsInr,
      fuelType: fuelType ?? this.fuelType,
      fuelRateInr: fuelRateInr ?? this.fuelRateInr,
      maxFuelContributionPerSeat:
          maxFuelContributionPerSeat ?? this.maxFuelContributionPerSeat,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'driverId': driverId,
        'fromCity': fromCity,
        'toCity': toCity,
        'departureTime': departureTime.toIso8601String(),
        'seatsTotal': seatsTotal,
        'seatsAvailable': seatsAvailable,
        'pricePerSeat': pricePerSeat,
        'vehicle': vehicle.toJson(),
        'stops': stops,
        'driverName': driverName,
        'driverRating': driverRating,
        'driverRatingCount': driverRatingCount,
        'distanceKm': distanceKm,
        'tollCostsInr': tollCostsInr,
        'fuelType': fuelType.name,
        'fuelRateInr': fuelRateInr,
        'maxFuelContributionPerSeat': maxFuelContributionPerSeat,
        'publishedAt': publishedAt.toIso8601String(),
      };

  factory Trip.fromJson(Map<String, dynamic> json) {
    final departure = DateTime.parse(json['departureTime'] as String);
    final fuelTypeRaw = json['fuelType'] as String?;
    return Trip(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      fromCity: json['fromCity'] as String,
      toCity: json['toCity'] as String,
      departureTime: departure,
      seatsTotal: json['seatsTotal'] as int,
      seatsAvailable: json['seatsAvailable'] as int,
      pricePerSeat: json['pricePerSeat'] as int,
      vehicle: Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
      stops: (json['stops'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      driverName: json['driverName'] as String? ?? '',
      driverRating: (json['driverRating'] as num?)?.toDouble() ?? 4.5,
      driverRatingCount: json['driverRatingCount'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      tollCostsInr: (json['tollCostsInr'] as num?)?.toDouble() ?? 0,
      fuelType: fuelTypeRaw == null
          ? FuelType.petrol
          : FuelType.values.firstWhere(
              (f) => f.name == fuelTypeRaw,
              orElse: () => FuelType.petrol,
            ),
      fuelRateInr: (json['fuelRateInr'] as num?)?.toDouble() ??
          FuelShareConstants.defaultPetrolInrPerLiter,
      maxFuelContributionPerSeat:
          json['maxFuelContributionPerSeat'] as int? ?? json['pricePerSeat'] as int,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : departure,
    );
  }
}
