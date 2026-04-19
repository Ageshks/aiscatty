import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeController extends GetxController {
  var pets = [].obs;
  var isLoading = false.obs;

  double? userLat;
  double? userLng;

  @override
  void onInit() {
    super.onInit();
    loadKeralaPets(); // default load
  }

  // 🔥 LOAD ALL KERALA PETS
  Future<void> loadKeralaPets() async {
    try {
      isLoading.value = true;

      final snapshot = await FirebaseFirestore.instance
          .collection('pets')
          .orderBy('createdAt', descending: true)
          .get();

      pets.value = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }

  // 🔥 LOAD NEARBY PETS (10KM)
  Future<void> loadNearbyPets() async {
    try {
      isLoading.value = true;

      // 📍 Permission
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar("Permission", "Location denied permanently");
        return;
      }

      // 📍 Get location
      Position position = await Geolocator.getCurrentPosition();

      userLat = position.latitude;
      userLng = position.longitude;

      final snapshot =
          await FirebaseFirestore.instance.collection('pets').get();

      List nearbyPets = [];

      for (var doc in snapshot.docs) {
        final pet = doc.data();

        if (pet['lat'] == null || pet['lng'] == null) continue;

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

      pets.value = nearbyPets;

    } catch (e) {
      print(e);
    } finally {
      isLoading.value = false;
    }
  }
}