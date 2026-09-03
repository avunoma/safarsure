class TripRating {
  const TripRating({
    required this.id,
    required this.requestId,
    required this.tripId,
    required this.raterId,
    required this.rateeId,
    required this.stars,
    this.comment = '',
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String tripId;
  final String raterId;
  final String rateeId;
  final int stars;
  final String comment;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'requestId': requestId,
        'tripId': tripId,
        'raterId': raterId,
        'rateeId': rateeId,
        'stars': stars,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TripRating.fromJson(Map<String, dynamic> json) {
    return TripRating(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      tripId: json['tripId'] as String,
      raterId: json['raterId'] as String,
      rateeId: json['rateeId'] as String,
      stars: json['stars'] as int,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
