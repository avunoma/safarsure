import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:safarsure/core/config/app_config.dart';
import 'package:safarsure/core/firebase/firebase_options_stub.dart';
import 'package:safarsure/data/models/user.dart';

/// Optional Firebase Auth. Falls back to demo auth when not configured.
class FirebaseService {
  FirebaseService._();

  static bool _initialized = false;
  static bool _available = false;

  static bool get isAvailable => _available;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!AppConfig.firebaseEnabled) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _available = true;
    } catch (_) {
      _available = false;
    }
  }

  static Future<AppUser?> signInWithGoogle() async {
    if (!_available) return null;

    final googleSignIn = GoogleSignIn();
    final account = await googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    final result =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final fbUser = result.user;
    if (fbUser == null) return null;

    return AppUser(
      id: fbUser.uid,
      name: fbUser.displayName ?? 'Traveller',
      phone: fbUser.phoneNumber ?? '',
      email: fbUser.email,
      photoUrl: fbUser.photoURL,
      authMethod: AuthMethod.google,
    );
  }

  static Future<void> signOut() async {
    if (!_available) return;
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}
