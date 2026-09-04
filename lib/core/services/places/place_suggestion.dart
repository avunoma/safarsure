/// Canonical value stored in search fields; [displayLabel] shown in the list.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.canonicalName,
    required this.displayLabel,
    this.placeId,
  });

  final String canonicalName;
  final String displayLabel;
  final String? placeId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaceSuggestion &&
          runtimeType == other.runtimeType &&
          canonicalName == other.canonicalName &&
          displayLabel == other.displayLabel;

  @override
  int get hashCode => Object.hash(canonicalName, displayLabel);
}
