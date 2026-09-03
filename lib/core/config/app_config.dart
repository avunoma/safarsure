/// Runtime config via --dart-define (see README).
abstract final class AppConfig {
  static const firebaseEnabled = bool.fromEnvironment(
    'FIREBASE_ENABLED',
    defaultValue: false,
  );

  static const mapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: '',
  );

  static bool get hasMapsApiKey => mapsApiKey.isNotEmpty;
}
