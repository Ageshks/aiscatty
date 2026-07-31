import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/app_colors.dart';

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
              final data = pet.data() as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      data['mediaUrl'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),

                  title: Text(data['name'] ?? "Pet"),
                  subtitle: Text(data['breed'] ?? ""),

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _confirmDelete(context, pet.id);
                    },
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