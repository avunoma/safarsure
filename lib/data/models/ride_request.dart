enum RequestStatus { waiting, confirmed, declined }

class RideRequest {
  const RideRequest({
    required this.id,
    required this.tripId,
    required this.riderId,
    required this.riderName,
    required this.seats,
    this.note = '',
    this.status = RequestStatus.waiting,
    this.pickupPoint,
    this.pickupTime,
    this.createdAt,
  });

  final String id;
  final String tripId;
  final String riderId;
  final String riderName;
  final int seats;
  final String note;
  final RequestStatus status;
  final String? pickupPoint;
  final DateTime? pickupTime;
  final DateTime? createdAt;

  RideRequest copyWith({
    String? id,
    String? tripId,
    String? riderId,
    String? riderName,
    int? seats,
    String? note,
    RequestStatus? status,
    String? pickupPoint,
    DateTime? pickupTime,
    DateTime? createdAt,
  }) {
    return RideRequest(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      seats: seats ?? this.seats,
      note: note ?? this.note,
      status: status ?? this.status,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      pickupTime: pickupTime ?? this.pickupTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'riderId': riderId,
        'riderName': riderName,
        'seats': seats,
        'note': note,
        'status': status.name,
        'pickupPoint': pickupPoint,
        'pickupTime': pickupTime?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      riderId: json['riderId'] as String,
      riderName: json['riderName'] as String,
      seats: json['seats'] as int,
      note: json['note'] as String? ?? '',
      status: RequestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RequestStatus.waiting,
      ),
      pickupPoint: json['pickupPoint'] as String?,
      pickupTime: json['pickupTime'] != null
          ? DateTime.parse(json['pickupTime'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
