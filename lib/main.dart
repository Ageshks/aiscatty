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
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// ✅ GLOBAL CONTROLLERS (ONLY ONCE HERE)
  Get.put(FavoritesController(), permanent: true);
  Get.put(ChatController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Pet Adoption Kerala 🐾',
      debugShowCheckedModeBanner: false,

      /// ✅ GLOBAL THEME (SAFE)
      theme: ThemeData(
        primaryColor: const Color(0xFF2ECC71),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),

      /// ✅ SAFE INITIAL ROUTE
      initialRoute: '/splash',

      /// ✅ ROUTES (CLEAN & COMPLETE)
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