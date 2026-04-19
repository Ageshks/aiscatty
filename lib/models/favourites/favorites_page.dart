import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/app_colors.dart';
import '../../widgets/pet_card.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.lightGreen,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.lightGreen,
        title: const Text(
          "Favorites ❤️",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          // ⏳ LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ ERROR
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          final docs = snapshot.data?.docs ?? [];

          // 🐱 EMPTY STATE
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Image.network(
                    "https://cdn-icons-png.flaticon.com/512/616/616430.png",
                    height: 120,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "No favorites yet ❤️",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Start adding pets you love 🐾",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // ❤️ FAVORITES LIST
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final pet = data['petData'] ?? {};

              return PetCard(
                petId: data['petId'] ?? "", // ✅ FIXED

                // ✅ SAFE DATA
                mediaUrl: pet['mediaUrl'] ?? "https://placedog.net/500",
                mediaType: pet['mediaType'] ?? "image",
                name: pet['name'] ?? "Unknown",
                breed: pet['breed'] ?? "Unknown",
                location: pet['location'] ?? "Unknown",

                onTap: () =>
                    Get.toNamed('/pet-details', arguments: pet),
              );
            },
          );
        },
      ),
    );
  }
}