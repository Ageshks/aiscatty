import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_notification_listener.dart';
import '../../services/google_sign_in_service.dart';
import '../../services/notification_service.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔐 LOGIN
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Don't stop login if notification initialization fails
      try {
        await NotificationService.init();
        ChatNotificationListener.init();
      } catch (e) {
        debugPrint("Notification init failed: $e");
      }

      Get.offAllNamed('/home');

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Get.snackbar("Error", "No account found");
      } else if (e.code == 'wrong-password') {
        Get.snackbar("Error", "Wrong password");
      } else {
        Get.snackbar("Error", e.message ?? "Login failed");
      }
    }
  }

  /// 🔵 GOOGLE SIGN-IN
  ///
  /// Signs in through Google, then reuses the exact same post-login steps as
  /// [login]: create the profile document when it is missing, start the chat
  /// listeners and go to Home.
  Future<void> signInWithGoogle() async {
    try {
      final outcome = await GoogleSignInService.signIn();

      // User closed the Google account picker – nothing to report.
      if (outcome.isCancelled) return;

      if (!outcome.isSuccess) {
        Get.snackbar(
          "Google Sign-In",
          outcome.errorMessage ?? "Could not sign in with Google",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      final user = outcome.credential?.user;
      if (user == null) {
        Get.snackbar("Google Sign-In", "Could not read your Google account");
        return;
      }

      await _ensureUserDocument(user);

      // Don't stop login if notification initialization fails
      try {
        await NotificationService.init();
        ChatNotificationListener.init();
      } catch (e) {
        debugPrint("Notification init failed: $e");
      }

      Get.offAllNamed('/home');
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      Get.snackbar("Error", "Something went wrong. Please try again.");
    }
  }

  /// Creates `users/{uid}` for first-time Google users.
  ///
  /// Existing profiles are never overwritten – only the last login timestamp is
  /// refreshed so email/password accounts keep their name, phone and district.
  Future<void> _ensureUserDocument(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      await docRef.set({
        "lastLoginAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    final fallbackName = user.email?.split('@').first ?? 'Aiscatty User';

    await docRef.set({
      "uid": user.uid,
      "name": user.displayName ?? fallbackName,
      "email": user.email ?? "",
      "phone": user.phoneNumber ?? "",
      "profileImage": user.photoURL ?? "",
      "bio": "",
      "city": "",
      "state": "",
      "district": "",
      "showPhone": false,
      "authProvider": "google",
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// 🔑 FORGOT PASSWORD
  ///
  /// Sends Firebase's password reset email. Returns `true` when the request was
  /// accepted, `false` when it failed (a message is shown either way).
  Future<bool> resetPassword(String email) async {
    final trimmed = email.trim();

    if (trimmed.isEmpty) {
      Get.snackbar("Email required", "Please enter your registered email");
      return false;
    }

    try {
      await _auth.sendPasswordResetEmail(email: trimmed);
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          Get.snackbar("Invalid email", "Please enter a valid email address");
          break;
        case 'user-not-found':
          Get.snackbar(
            "Account not found",
            "No account is registered with this email",
          );
          break;
        case 'too-many-requests':
          Get.snackbar(
            "Too many attempts",
            "Please wait a few minutes and try again",
          );
          break;
        case 'network-request-failed':
          Get.snackbar(
            "Network error",
            "Check your connection and try again",
          );
          break;
        default:
          Get.snackbar(
            "Error",
            e.message ?? "Could not send the reset email",
          );
      }
      return false;
    } catch (e) {
      debugPrint("Password reset error: $e");
      Get.snackbar("Error", "Something went wrong. Please try again.");
      return false;
    }
  }

  /// 🆕 REGISTER with Firestore document creation
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      // Create Firestore document for the user
      await _firestore.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "name": name,
        "email": email,
        "phone": phone,
        "profileImage": "",
        "bio": "",
        "city": "",
        "state": "",
        "showPhone": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // Don't stop registration if notification initialization fails
      try {
        await NotificationService.init();
        ChatNotificationListener.init();
      } catch (e) {
        debugPrint("Notification init failed: $e");
      }

      // Navigate first, then show snackbar on the home page
      Get.offAllNamed('/home');
      await Future.delayed(const Duration(milliseconds: 300));
      Get.snackbar(
        "Welcome! 🎉",
        "Account created successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Get.snackbar("Error", "Email already registered");
      } else if (e.code == 'weak-password') {
        Get.snackbar("Error", "Password must be at least 6 characters");
      } else {
        Get.snackbar("Error", e.message ?? "Something went wrong");
      }
    }
  }

  /// 🚪 LOGOUT
  Future<void> logout() async {
    // Clear the cached Google session too (no-op for email/password accounts).
    await GoogleSignInService.signOut();
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}