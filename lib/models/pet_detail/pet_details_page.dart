import 'package:aiscatty/models/chat/chat_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/favourites/favorites_controller.dart';
import '../../utils/app_colors.dart';
import '../../widgets/pet_status_badge.dart';
import '../../widgets/pet_video_section.dart';

class PetDetailsPage extends StatelessWidget {
  PetDetailsPage({super.key});

  final pet = Get.arguments is Map ? (Get.arguments as Map).cast<String, dynamic>() : <String, dynamic>{};
  final favController = Get.find<FavoritesController>();

  @override
  Widget build(BuildContext context) {
    final petId = pet['id']?.toString() ?? '';
    final ownerId = pet['ownerId']?.toString();
    final isOwner = ownerId == FirebaseAuth.instance.currentUser?.uid;

    // 🛡️ Safe field reads — never crash on missing Firestore fields.
    final name = pet['name']?.toString() ?? 'Pet';
    final breed = pet['breed']?.toString() ?? 'Unknown Breed';
    final location = pet['location']?.toString() ?? '';
    final district = pet['district']?.toString() ?? '';
    final place = [
      if (location.isNotEmpty) location,
      if (district.isNotEmpty) district,
    ].join(', ');
    final status = pet['status']?.toString() ?? 'available';
    final videoUrl = pet['statusVideoUrl']?.toString() ?? '';
    final age = pet['age']?.toString() ?? '';
    final gender = pet['gender']?.toString() ?? '';

    // Adoption availability per the status flow.
    final canRequest = status == 'available';
    final buttonLabel = switch (status) {
      'pending' => 'Adoption in progress',
      'adopted' => 'Adopted ❤️',
      _ => 'Request Adoption',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [
        SingleChildScrollView(
          child: Column(children: [
            Stack(children: [
              SizedBox(height: 350, width: double.infinity, child: Image.network(pet['mediaUrl']?.toString() ?? 'https://placedog.net/500', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.lightBlue, child: const Center(child: Icon(Icons.pets, size: 60, color: Colors.grey))))),
              Container(height: 350, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: .4), Colors.transparent]))),
              Positioned(top: 50, left: 16, child: _circleButton(Icons.arrow_back, Get.back)),
              Positioned(top: 50, right: 16, child: Obx(() {
                final isFav = favController.isFavorite(petId);
                return _circleButton(isFav ? Icons.favorite : Icons.favorite_border, () => favController.toggleFavorite(petId, pet), color: isFav ? Colors.red : Colors.black);
              })),
            ]),
            Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              PetStatusBadge(status: status),
              const SizedBox(height: 6), Text(breed, style: const TextStyle(color: Colors.grey)),
              if (age.isNotEmpty || gender.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text([age, gender].where((v) => v.isNotEmpty).join(' • '), style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 16), Row(children: [const Icon(Icons.location_on, size: 16, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(place.isEmpty ? 'Unknown' : place, style: const TextStyle(color: Colors.grey)))]),
              const SizedBox(height: 20), const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), const SizedBox(height: 10), Text(pet['description']?.toString() ?? 'Friendly pet looking for a loving home 🐾'), const SizedBox(height: 120),

              // 🎥 STATUS VIDEO — loads only when tapped, never on page load.
              if (videoUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: PetVideoSection(videoUrl: videoUrl, petName: name),
                ),
            ])),
          ]),
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.fromLTRB(16, 10, 16, 20), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 10)]), child: SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: isOwner || !canRequest ? null : () => _requestAdoption(ownerId, petId),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: Colors.grey.shade300), icon: const Icon(Icons.favorite_outline), label: Text(buttonLabel),
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
