import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Status of a Google Sign-In attempt.
enum GoogleSignInStatus {
  /// Firebase returned a valid [UserCredential].
  success,

  /// The user dismissed the Google account picker – no error to report.
  cancelled,

  /// Google Sign-In is not available on this platform / build target.
  unsupported,

  /// Anything else (configuration, network, Firebase error).
  error,
}

/// Result wrapper so callers never have to catch plugin exceptions.
class GoogleSignInOutcome {
  const GoogleSignInOutcome._(
    this.status, {
    this.credential,
    this.errorMessage,
  });

  final GoogleSignInStatus status;
  final UserCredential? credential;
  final String? errorMessage;

  bool get isSuccess => status == GoogleSignInStatus.success;
  bool get isCancelled => status == GoogleSignInStatus.cancelled;

  factory GoogleSignInOutcome.success(UserCredential credential) =>
      GoogleSignInOutcome._(
        GoogleSignInStatus.success,
        credential: credential,
      );

  factory GoogleSignInOutcome.cancelled() =>
      const GoogleSignInOutcome._(GoogleSignInStatus.cancelled);

  factory GoogleSignInOutcome.unsupported([String? message]) =>
      GoogleSignInOutcome._(
        GoogleSignInStatus.unsupported,
        errorMessage: message,
      );

  factory GoogleSignInOutcome.error(String message) =>
      GoogleSignInOutcome._(GoogleSignInStatus.error, errorMessage: message);
}

/// Google Sign-In for Aiscatty, built on the `google_sign_in` 7.x singleton API
/// and wired into the existing Firebase Authentication flow.
///
/// ## Android setup (required once)
/// 1. Firebase Console ➜ Project settings ➜ *Your apps* ➜ Android
///    (`com.agesh.aiscatty`) ➜ **Add fingerprint** and paste the SHA-1 values
///    for every signing key you build with (debug **and** release).
/// 2. Firebase Console ➜ Authentication ➜ Sign-in method ➜ enable **Google**.
/// 3. Re-download `android/app/google-services.json` and rebuild.
///
/// Step 3 matters because `google_sign_in` 7.x uses Android Credential Manager,
/// which needs a *web* OAuth client ID. Registering the SHA in Firebase makes
/// Firebase write the web client into the `oauth_client` list of
/// `google-services.json`, which the plugin then picks up automatically.
///
/// If you would rather **not** re-download `google-services.json`, paste the web
/// client ID (Google Cloud Console ➜ APIs & Services ➜ Credentials ➜
/// "Web client (auto created by Google Service)") into [serverClientId] below.
///
/// Nothing here is required for the rest of the app to work: on a project that
/// has not been configured yet the caller simply receives a
/// [GoogleSignInStatus.error] outcome instead of a crash.
class GoogleSignInService {
  GoogleSignInService._();

  /// Optional web OAuth client ID. Leave empty when `google-services.json`
  /// already contains a web OAuth client entry (the recommended Firebase flow).
  static const String serverClientId = '';

  /// `initialize` must run exactly once per app launch – cache the future.
  static Future<void>? _initialization;

  static bool get isSupported {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static Future<void> _ensureInitialized() async {
    final Future<void>? existing = _initialization;
    if (existing != null) {
      await existing;
      return;
    }

    final Future<void> future = GoogleSignIn.instance.initialize(
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    _initialization = future;

    try {
      await future;
    } catch (_) {
      // Allow a later retry instead of caching a permanently failed future.
      _initialization = null;
      rethrow;
    }
  }

  /// Runs the interactive Google Sign-In flow and exchanges the Google ID token
  /// for a Firebase credential. Never throws.
  static Future<GoogleSignInOutcome> signIn() async {
    if (!isSupported) {
      return GoogleSignInOutcome.unsupported(
        'Google Sign-In is not available on this platform.',
      );
    }

    try {
      await _ensureInitialized();

      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();

      final String? idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return GoogleSignInOutcome.error(
          'Google did not return an ID token. Please check the Google '
          'sign-in configuration for this app.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      return GoogleSignInOutcome.success(userCredential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return GoogleSignInOutcome.cancelled();
      }
      debugPrint('⚠️ GoogleSignInException: ${e.code} – ${e.description}');
      return GoogleSignInOutcome.error(_friendlyGoogleError(e));
    } on FirebaseAuthException catch (e) {
      return GoogleSignInOutcome.error(_friendlyFirebaseError(e));
    } on UnsupportedError catch (e) {
      debugPrint('⚠️ Google Sign-In unsupported: $e');
      return GoogleSignInOutcome.unsupported(
        'Google Sign-In is not available on this platform.',
      );
    } catch (e) {
      debugPrint('⚠️ Google Sign-In failed: $e');
      return GoogleSignInOutcome.error(
        'Could not sign in with Google. Please try again.',
      );
    }
  }

  /// Clears the cached Google session. Safe to call at any time.
  static Future<void> signOut() async {
    if (!isSupported) return;
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      // Never block a logout because of a Google session caching issue.
      debugPrint('⚠️ Google sign-out skipped: $e');
    }
  }

  static String _friendlyGoogleError(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google Sign-In is not configured yet. Add this app\'s SHA-1 '
            'fingerprint in Firebase and enable the Google sign-in provider.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'The Google sign-in provider is not configured correctly.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Sign-in window is unavailable. Please try again.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'This Google account cannot be used right now. '
            'Please sign in again.';
      default:
        return e.description ??
            'Could not sign in with Google. Please try again.';
    }
  }

  static String _friendlyFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'This email is already registered with a password. '
            'Please log in with your email and password instead.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-credential':
      case 'internal-error':
        return 'Could not verify this Google account. Please try again.';
      default:
        return e.message ?? 'Google sign-in failed. Please try again.';
    }
  }
}
