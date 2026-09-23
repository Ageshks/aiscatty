import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/app_colors.dart';
import '../../widgets/pet_status_badge.dart';
import 'pet_edit_page.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.lightGreen,
        appBar: AppBar(
          title: const Text("My Listings 🐾"),
          backgroundColor: AppColors.primary,
        ),
        body: const Center(
          child: Text("Please login to see your listings"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightGreen,

      appBar: AppBar(
        title: const Text("My Listings 🐾"),
        backgroundColor: AppColors.primary,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pets')
            .where('ownerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("❌ MyListings error: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    "Error loading listings ❌\n${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text("Loading your listings..."),
                ],
              ),
            );
          }

          final pets = snapshot.data!.docs;

          if (pets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    "No pets added yet 🐶",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tap + on home page to add one!",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              final data = pet.data() as Map<String, dynamic>? ?? {};

              // 🛡️ Safe reads for every field.
              final name = data['name']?.toString() ?? 'Pet';
              final breed = data['breed']?.toString() ?? '';
              final location = data['location']?.toString() ?? '';
              final district = data['district']?.toString() ?? '';
              final place = [
                if (location.isNotEmpty) location,
                if (district.isNotEmpty) district,
              ].join(', ');
              final status = data['status']?.toString() ?? 'available';
              final hasVideo =
                  (data['statusVideoUrl']?.toString() ?? '').isNotEmpty;
              final mediaUrl = data['mediaUrl']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: mediaUrl.isEmpty
                                ? Container(width: 60, height: 60, color: AppColors.lightBlue, child: const Icon(Icons.pets))
                                : Image.network(mediaUrl, width: 60, height: 60, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: AppColors.lightBlue, child: const Icon(Icons.pets))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                if (breed.isNotEmpty) Text(breed, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                if (place.isNotEmpty) Text(place, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          PetStatusBadge(status: status, compact: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 🎥 Video availability + ❤️ request count + actions
                      Row(
                        children: [
                          if (hasVideo)
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Text('🎥 Status Video',
                                  style: TextStyle(fontSize: 12, color: AppColors.black)),
                            ),
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('adoption_requests')
                                .where('petId', isEqualTo: pet.id)
                                .get(),
                            builder: (context, reqSnap) {
                              final count = reqSnap.data?.docs.length ?? 0;
                              return Text('❤️ $count Requests',
                                  style: const TextStyle(fontSize: 12, color: AppColors.black));
                            },
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.blue),
                            tooltip: 'Edit listing',
                            onPressed: () => Get.to(() => PetEditPage(
                                  petId: pet.id,
                                  petData: data,
                                )),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete listing',
                            onPressed: () => _confirmDelete(context, pet.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 🔥 CONFIRM DELETE
  void _confirmDelete(BuildContext context, String petId) {
    Get.dialog(
      AlertDialog(
        title: const Text("Delete Pet"),
        content: const Text("Are you sure you want to delete this pet?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _deletePetAndChats(petId);
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  /// 🔥 DELETE PET + CHATS + MESSAGES
  Future<void> _deletePetAndChats(String petId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      /// 1️⃣ DELETE PET
      await firestore.collection('pets').doc(petId).delete();

      /// 2️⃣ FIND RELATED CHATS
      final chats = await firestore
          .collection('chats')
          .where('petId', isEqualTo: petId)
          .get();

      for (var chat in chats.docs) {

        /// 3️⃣ DELETE MESSAGES
        final messages = await chat.reference
            .collection('messages')
            .get();

        for (var msg in messages.docs) {
          await msg.reference.delete();
        }

        /// 4️⃣ DELETE CHAT
        await chat.reference.delete();
      }

      Get.snackbar("Success", "Pet deleted successfully 🐾");

    } catch (e) {
      print("❌ Delete error: $e");
      Get.snackbar("Error", "Failed to delete");
    }
  }
}