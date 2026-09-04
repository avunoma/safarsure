import 'dart:convert';

import 'package:safarsure/core/utils/privacy.dart';
import 'package:safarsure/data/models/chat_message.dart';
import 'package:safarsure/data/models/ride_request.dart';
import 'package:safarsure/data/models/trip.dart';
import 'package:safarsure/data/models/vehicle.dart';

abstract class CloudSyncService {
  bool get isAvailable;

  Future<void> upsertTrip(Trip trip);

  Future<List<Trip>> fetchTrips();

  Future<void> upsertRequest(RideRequest request, {required bool revealRider});

  Future<List<RideRequest>> fetchRequestsForTrip(String tripId);

  Future<RideRequest?> fetchRequestById(String requestId);

  Future<void> sendMessage(ChatMessage message);

  Future<List<ChatMessage>> fetchMessages(String requestId);
}

RideRequest requestToCloud(
  RideRequest request, {
  required bool revealRider,
}) {
  return request.copyWith(
    riderName: revealRider
        ? revealedFirstName(request.riderName)
        : 'Rider',
  );
}

ChatMessage messageToCloud(ChatMessage message) {
  return ChatMessage(
    id: message.id,
    requestId: message.requestId,
    senderId: message.senderId,
    senderName: revealedFirstName(message.senderName),
    text: message.text,
    sentAt: message.sentAt,
  );
}

Map<String, dynamic> requestToMap(RideRequest request) => {
      'id': request.id,
      'tripId': request.tripId,
      'riderId': request.riderId,
      'riderName': request.riderName,
      'seats': request.seats,
      'note': request.note,
      'status': request.status.name,
      'pickupPoint': request.pickupPoint,
      'pickupTime': request.pickupTime?.toIso8601String(),
      'createdAt': request.createdAt?.toIso8601String(),
    };

RideRequest requestFromMap(Map<String, dynamic> map) {
  return RideRequest(
    id: map['id'] as String,
    tripId: map['tripId'] as String,
    riderId: map['riderId'] as String,
    riderName: map['riderName'] as String,
    seats: map['seats'] as int,
    note: map['note'] as String? ?? '',
    status: RequestStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => RequestStatus.waiting,
    ),
    pickupPoint: map['pickupPoint'] as String?,
    pickupTime: map['pickupTime'] != null
        ? DateTime.parse(map['pickupTime'] as String)
        : null,
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'] as String)
        : null,
  );
}

Map<String, dynamic> messageToMap(ChatMessage message) => {
      'id': message.id,
      'requestId': message.requestId,
      'senderId': message.senderId,
      'senderName': message.senderName,
      'text': message.text,
      'sentAt': message.sentAt.toIso8601String(),
    };

ChatMessage messageFromMap(Map<String, dynamic> map) {
  return ChatMessage(
    id: map['id'] as String,
    requestId: map['requestId'] as String,
    senderId: map['senderId'] as String,
    senderName: map['senderName'] as String,
    text: map['text'] as String,
    sentAt: DateTime.parse(map['sentAt'] as String),
  );
}

/// Cloud trips omit driver name/phone; aggregate rating only.
Trip tripToCloud(Trip trip) => trip.copyWith(driverName: '');

Map<String, dynamic> tripToMap(Trip trip) {
  final cloud = tripToCloud(trip);
  return {
    'id': cloud.id,
    'driverId': cloud.driverId,
    'fromCity': cloud.fromCity,
    'toCity': cloud.toCity,
    'departureTime': cloud.departureTime.toIso8601String(),
    'seatsTotal': cloud.seatsTotal,
    'seatsAvailable': cloud.seatsAvailable,
    'pricePerSeat': cloud.pricePerSeat,
    'vehicleMake': cloud.vehicle.make,
    'vehicleModel': cloud.vehicle.model,
    'vehicleColor': cloud.vehicle.color,
    'stops': cloud.stops.join('|'),
    'driverRating': cloud.driverRating,
    'driverRatingCount': cloud.driverRatingCount,
  };
}

Trip tripFromMap(Map<String, dynamic> map) {
  final stopsRaw = map['stops'] as String? ?? '';
  return Trip(
    id: map['id'] as String,
    driverId: map['driverId'] as String,
    fromCity: map['fromCity'] as String,
    toCity: map['toCity'] as String,
    departureTime: DateTime.parse(map['departureTime'] as String),
    seatsTotal: map['seatsTotal'] as int,
    seatsAvailable: map['seatsAvailable'] as int,
    pricePerSeat: map['pricePerSeat'] as int,
    vehicle: Vehicle(
      make: map['vehicleMake'] as String,
      model: map['vehicleModel'] as String,
      color: map['vehicleColor'] as String,
    ),
    stops: stopsRaw.isEmpty
        ? const []
        : stopsRaw.split('|').where((s) => s.isNotEmpty).toList(),
    driverRating: (map['driverRating'] as num?)?.toDouble() ?? 4.5,
    driverRatingCount: map['driverRatingCount'] as int? ?? 0,
  );
}

/// Decode a trip stored as JSON in a single Firestore string field.
Trip? tripFromJsonField(String? json) {
  if (json == null || json.isEmpty) return null;
  return tripFromMap(jsonDecode(json) as Map<String, dynamic>);
}

String tripToJsonField(Trip trip) => jsonEncode(tripToMap(trip));
