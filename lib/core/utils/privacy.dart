import 'package:safarsure/data/models/ride_request.dart';

/// Identity is revealed only after a seat request is confirmed.
bool identityRevealed(RequestStatus? status) =>
    status == RequestStatus.confirmed;

String privatePartyLabel({required bool isDriver}) =>
    isDriver ? 'Verified driver' : 'Rider';

String revealedFirstName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return 'Traveller';
  return trimmed.split(RegExp(r'\s+')).first;
}

String formatRating(double rating, int count) {
  if (count <= 0) return rating.toStringAsFixed(1);
  return '${rating.toStringAsFixed(1)} ($count)';
}
