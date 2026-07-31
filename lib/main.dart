import 'package:aiscatty/models/auth/login_page.dart';
import 'package:aiscatty/models/auth/splash_page.dart';
import 'package:aiscatty/models/chat/chat_controller.dart';
import 'package:aiscatty/models/chat/chat_detail_page.dart';
import 'package:aiscatty/models/favourites/favorites_controller.dart';
import 'package:aiscatty/models/favourites/favorites_page.dart';
import 'package:aiscatty/models/navigation/main_navigation.dart';
import 'package:aiscatty/models/pet_detail/pet_details_page.dart';
import 'package:aiscatty/models/profile/MyListingsPage.dart';
import 'package:aiscatty/models/profile/adoptionRequestPage.dart';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';

/// 🔥 BACKGROUND HANDLER
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Background Message: ${message.notification?.title}");
  
  // Show local notification for background FCM messages
  if (message.notification != null) {
    await _showBackgroundNotification(
      message.notification!.title ?? 'New Message',
      message.notification!.body ?? '',
    );
  }
}

/// Show a local notification from background FCM handler
Future<void> _showBackgroundNotification(String title, String body) async {
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android is configured through firebase_options.dart. iOS reads the
  // bundled GoogleService-Info.plist; passing Android-only options on iOS
  // previously stopped the app before its first screen was shown.
  if (defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  /// 🔥 FCM BACKGROUND SETUP
  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

  /// ✅ GLOBAL CONTROLLERS
  Get.put(FavoritesController(), permanent: true);
  Get.put(ChatController(), permanent: true);

  /// 🔥 INIT NOTIFICATIONS
  // Notification setup must never block launching the app. It is repeated
  // after login, when an authenticated user is available.
  NotificationService.init();

  /// 📱 INIT LOCAL NOTIFICATIONS (system notification bar)
  await initLocalNotifications();

  /// ⏰ INIT WORKMANAGER (periodic background checks)
  await initWorkmanager();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Pet Adoption Kerala 🐾',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primaryColor: const Color(0xFF2ECC71),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),

      initialRoute: '/splash',

      getPages: [

        /// AUTH
        GetPage(name: '/splash', page: () => const SplashPage()),
        GetPage(name: '/login', page: () => LoginPage()),

        /// MAIN
        GetPage(name: '/home', page: () => MainNavigation()),

        /// PET
        GetPage(name: '/pet-details', page: () => PetDetailsPage()),

        /// FAVORITES
        GetPage(name: '/favorites', page: () => const FavoritesPage()),

        /// CHAT
        GetPage(name: '/chat-detail', page: () => ChatDetailPage()),

        /// PROFILE
        GetPage(name: '/my-listings', page: () => const MyListingsPage()),
        GetPage(
          name: '/adoption-requests',
          page: () => const AdoptionRequestsPage(),
        ),
      ],
    );
  }
}
