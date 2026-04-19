import 'package:aiscatty/models/auth/login_page.dart';
import 'package:aiscatty/models/navigation/main_navigation.dart';
import 'package:aiscatty/models/pet_detail/pet_details_page.dart';
import 'package:aiscatty/models/profile/adoptionRequestPage.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

class AppRoutes {
  static final routes = [
    GetPage(name: '/', page: () => LoginPage()),
    GetPage(name: '/home', page: () => MainNavigation()),
    GetPage(name: '/pet-details', page: () => PetDetailsPage()),
    GetPage(name: '/adoption-requests', page: () => AdoptionRequestsPage()),
  ];
}