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
  });

  final String id;
  final String driverId;
  final String fromCity;
  final String toCity;
  final DateTime departureTime;
  final int seatsTotal;
  final int seatsAvailable;
  final int pricePerSeat;
  final Vehicle vehicle;
  final List<String> stops;
  final String driverName;
  final double driverRating;
  final int driverRatingCount;

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
      };

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      driverId: json['driverId'] as String,
      fromCity: json['fromCity'] as String,
      toCity: json['toCity'] as String,
      departureTime: DateTime.parse(json['departureTime'] as String),
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
    );
  }
}
