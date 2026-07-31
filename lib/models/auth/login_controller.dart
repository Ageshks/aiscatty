import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_notification_listener.dart';
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
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}