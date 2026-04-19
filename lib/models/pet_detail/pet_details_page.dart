import 'package:aiscatty/models/chat/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../models/favourites/favorites_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetDetailsPage extends StatelessWidget {
  PetDetailsPage({super.key});

  final pet = Get.arguments ?? {};
  final favController = Get.find<FavoritesController>();
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final petId = pet['id'] ?? "temp_${DateTime.now().millisecondsSinceEpoch}";
    final ownerId = pet['ownerId'];

    print("🔥 PET DATA => $pet");
    print("👉 OWNER ID => $ownerId");
    print("👉 CURRENT USER => ${currentUser?.uid}");

    final isOwner = ownerId == currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// 🔥 CONTENT
          SingleChildScrollView(
            child: Column(
              children: [
                /// 🖼️ IMAGE
                Stack(
                  children: [
                    SizedBox(
                      height: 350,
                      width: double.infinity,
                      child: Image.network(
                        pet['mediaUrl'] ?? "https://placedog.net/500",
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      height: 350,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 16,
                      child: _circleButton(Icons.arrow_back, () {
                        Get.back();
                      }),
                    ),

                    /// ❤️ FAVORITE
                    Positioned(
                      top: 50,
                      right: 16,
                      child: Obx(() {
                        final isFav = favController.isFavorite(petId);
                        return _circleButton(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          () {
                            favController.toggleFavorite(petId, pet);
                          },
                          color: isFav ? Colors.red : Colors.black,
                        );
                      }),
                    ),
                  ],
                ),

                /// 🐾 DETAILS
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet['name'] ?? "Unknown",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pet['breed'] ?? "Unknown Breed",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            pet['location'] ?? "Unknown",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "About",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        pet['description'] ??
                            "Friendly pet looking for a loving home 🐾",
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// 🔥 BOTTOM BUTTONS
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [
                  /// 💬 CHAT BUTTON
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isOwner
                          ? null
                          : () async {
                              if (ownerId == null) {
                                Get.snackbar("Error", "Owner not found");
                                print("❌ OWNER ID NULL => $pet");
                                return;
                              }
                              final chatController =
                                  Get.find<ChatController>();
                              final chatId = await chatController.createChat(
                                ownerId,
                                petId,
                              );
                              Get.toNamed('/chat-detail',
                                  arguments: {"chatId": chatId});
                            },
                      child: const Text("Chat"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// 🐾 ADOPT BUTTON
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isOwner
                          ? null
                          : () async {
                              if (ownerId == null) {
                                Get.snackbar("Error", "Owner not found");
                                return;
                              }
                              final chatController =
                                  Get.find<ChatController>();
                              final chatId = await chatController.createChat(
                                ownerId,
                                petId,
                              );
                              await chatController.sendMessage(
                                chatId,
                                "Hi! I am interested in adopting ${pet['name'] ?? "this pet"}",
                              );
                              Get.toNamed('/chat-detail',
                                  arguments: {"chatId": chatId});
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text("Adopt"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.black,
  }) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
      ),
    );
  }
}