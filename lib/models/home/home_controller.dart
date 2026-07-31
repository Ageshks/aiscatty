import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeController extends GetxController {
  var pets = [].obs;
  var isLoading = false.obs;

  double? userLat;
  double? userLng;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    loadKeralaPets();
  }

  /// 🔥 LOAD ALL PETS EXCEPT MY OWN
  Future<void> loadKeralaPets() async {
    try {
      isLoading.value = true;

      final currentUser = _auth.currentUser;

      final snapshot = await FirebaseFirestore.instance
          .collection('pets')
          .orderBy('createdAt', descending: true)
          .get();

      List allPets = [];

      for (var doc in snapshot.docs) {
        final pet = doc.data();

        // ❌ Skip my own pets
        if (pet['ownerId'] == currentUser?.uid) {
          continue;
        }

        pet['id'] = doc.id;
        allPets.add(pet);
      }

      pets.value = allPets;
    } catch (e) {
      print("❌ Home Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔥 LOAD NEARBY PETS (EXCLUDING MY OWN)
  Future<void> loadNearbyPets() async {
    try {
      isLoading.value = true;

      final currentUser = _auth.currentUser;

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          "Permission",
          "Location permission denied permanently",
        );
        return;
      }

      Position position =
          await Geolocator.getCurrentPosition();

      userLat = position.latitude;
      userLng = position.longitude;

      final snapshot = await FirebaseFirestore.instance
          .collection('pets')
          .get();

      List nearbyPets = [];

      for (var doc in snapshot.docs) {
        final pet = doc.data();

        // ❌ Skip my own pets
        if (pet['ownerId'] == currentUser?.uid) {
          continue;
        }

        if (pet['lat'] == null || pet['lng'] == null) {
          continue;
        }

        double distance = Geolocator.distanceBetween(
          userLat!,
          userLng!,
          pet['lat'],
          pet['lng'],
        );

        if (distance <= 10000) {
          pet['distance'] =
              (distance / 1000).toStringAsFixed(1);

          pet['id'] = doc.id;

          nearbyPets.add(pet);
        }
      }

      nearbyPets.sort((a, b) =>
          double.parse(a['distance'])
              .compareTo(double.parse(b['distance'])));

      pets.value = nearbyPets;
    } catch (e) {
      print("❌ Nearby Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔄 Refresh
  Future<void> refreshPets() async {
    await loadKeralaPets();
  }
}