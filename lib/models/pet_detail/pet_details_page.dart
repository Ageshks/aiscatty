import 'package:aiscatty/models/chat/chat_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/favourites/favorites_controller.dart';
import '../../utils/app_colors.dart';

class PetDetailsPage extends StatelessWidget {
  PetDetailsPage({super.key});

  final pet = Get.arguments ?? {};
  final favController = Get.find<FavoritesController>();

  @override
  Widget build(BuildContext context) {
    final petId = pet['id']?.toString() ?? '';
    final ownerId = pet['ownerId']?.toString();
    final isOwner = ownerId == FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        SingleChildScrollView(
          child: Column(children: [
            Stack(children: [
              SizedBox(height: 350, width: double.infinity, child: Image.network(pet['mediaUrl'] ?? 'https://placedog.net/500', fit: BoxFit.cover)),
              Container(height: 350, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: .4), Colors.transparent]))),
              Positioned(top: 50, left: 16, child: _circleButton(Icons.arrow_back, Get.back)),
              Positioned(top: 50, right: 16, child: Obx(() {
                final isFav = favController.isFavorite(petId);
                return _circleButton(isFav ? Icons.favorite : Icons.favorite_border, () => favController.toggleFavorite(petId, pet), color: isFav ? Colors.red : Colors.black);
              })),
            ]),
            Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pet['name'] ?? 'Unknown', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6), Text(pet['breed'] ?? 'Unknown Breed', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16), Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.grey), const SizedBox(width: 4), Text(pet['location'] ?? 'Unknown', style: const TextStyle(color: Colors.grey))]),
              const SizedBox(height: 20), const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), const SizedBox(height: 10), Text(pet['description'] ?? 'Friendly pet looking for a loving home 🐾'), const SizedBox(height: 120),
            ])),
          ]),
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.fromLTRB(16, 10, 16, 20), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 10)]), child: SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: isOwner ? null : () => _requestAdoption(ownerId, petId),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), icon: const Icon(Icons.favorite_outline), label: const Text('Request to Adopt'),
        )))),
      ]),
    );
  }

  Future<void> _requestAdoption(String? ownerId, String petId) async {
    if (ownerId == null || petId.isEmpty) { Get.snackbar('Error', 'This pet listing is incomplete.'); return; }
    try {
      await Get.find<ChatController>().requestAdoption(ownerId: ownerId, petId: petId, petName: pet['name']?.toString() ?? 'Pet');
      Get.snackbar('Request sent', 'The owner will be able to approve or decline it. Chat opens after approval.');
    } catch (error) { Get.snackbar('Could not send request', error.toString()); }
  }

  Widget _circleButton(IconData icon, VoidCallback onTap, {Color color = Colors.black}) => CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: Icon(icon, color: color), onPressed: onTap));
}
