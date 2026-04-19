import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesController extends GetxController {
  var favorites = <String>[].obs; // store petIds

  final user = FirebaseAuth.instance.currentUser;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  // 🔥 LOAD FAVORITES
  Future<void> loadFavorites() async {
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: user!.uid)
        .get();

    favorites.value =
        snapshot.docs.map((e) => e['petId'] as String).toList();
  }

  // ❤️ TOGGLE FAVORITE
  Future<void> toggleFavorite(String petId, Map petData) async {
    if (user == null) return;

    final favRef = FirebaseFirestore.instance.collection('favorites');

    final existing = await favRef
        .where('userId', isEqualTo: user!.uid)
        .where('petId', isEqualTo: petId)
        .get();

    if (existing.docs.isNotEmpty) {
      // ❌ REMOVE
      await existing.docs.first.reference.delete();
      favorites.remove(petId);
    } else {
      // ✅ ADD
      await favRef.add({
        "userId": user!.uid,
        "petId": petId,
        "petData": petData,
        "createdAt": DateTime.now(),
      });

      favorites.add(petId);
    }
  }

  bool isFavorite(String petId) {
    return favorites.contains(petId);
  }
}