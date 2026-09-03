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

  /// Shared demo Firestore for two-device testing without creating a project.
  static const demoCloudEnabled = bool.fromEnvironment(
    'DEMO_CLOUD_ENABLED',
    defaultValue: true,
  );

  static const demoFirebaseProjectId = String.fromEnvironment(
    'DEMO_FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  static const demoFirebaseApiKey = String.fromEnvironment(
    'DEMO_FIREBASE_API_KEY',
    defaultValue: '',
  );

  static bool get hasMapsApiKey => mapsApiKey.isNotEmpty;

  static bool get hasDemoCloudRest =>
      demoCloudEnabled &&
      demoFirebaseProjectId.isNotEmpty &&
      demoFirebaseApiKey.isNotEmpty;

  static bool get hasAnyCloud => firebaseEnabled || hasDemoCloudRest;
}
