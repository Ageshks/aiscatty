import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'background_service.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    /// 🔐 REQUEST PERMISSION
    await _fcm.requestPermission();

    /// 📲 GET TOKEN
    String? token = await _fcm.getToken();
    print("🔥 FCM TOKEN => $token");

    /// 💾 SAVE TOKEN
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        "fcmToken": token,
      }, SetOptions(merge: true));
    }

    /// 📩 FOREGROUND LISTENER - WhatsApp-style popup + system notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground Message: ${message.notification?.title}");
      final title = message.notification?.title ?? 'New Message';
      final body = message.notification?.body ?? '';
      
      // Show in-app snackbar
      _showFcmNotification(title, body);
      
      // Also show system notification
      _showSystemNotification(title, body);
    });
  }

  /// Show a WhatsApp-style in-app notification popup for FCM messages
  static void _showFcmNotification(String title, String body) {
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      duration: const Duration(seconds: 4),
      icon: const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xFF2ECC71),
        child: Icon(Icons.notifications, color: Colors.white, size: 18),
      ),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          Get.toNamed('/home');
        },
        child: const Text(
          'Open',
          style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Show a system notification via flutter_local_notifications
  static Future<void> _showSystemNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
