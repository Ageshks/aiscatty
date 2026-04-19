import 'package:aiscatty/models/home/nearby_pets_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pet_card.dart';
import '../../utils/app_colors.dart';
import '../add_pet/add_pet_page.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.lightGreen,
        title: const Text(
          "Pet Adoption 🐾",
          style: TextStyle(
            color: AppColors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Get.toNamed('/favorites'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.favorite_border,
                    color: AppColors.black),
              ),
            ),
          )
        ],
      ),

      body: Column(
        children: [

          // 🔥 PREMIUM HEADER
          GestureDetector(
            onTap: () => Get.to(() => const NearbyPetsPage()),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Find your new friend 🐶",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Adopt pets near you",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.pets,
                      color: Colors.white, size: 42),
                ],
              ),
            ),
          ),

          // 🔥 SECTION TITLE
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Pets Available in Kerala",
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 🔥 PET LIST
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              if (controller.pets.isEmpty) {
                return const Center(
                  child: Text(
                    "No pets available 🐾",
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: controller.pets.length,
                itemBuilder: (context, index) {
                  final pet = controller.pets[index];

                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: PetCard(
                      petId: pet['id'],
                      mediaUrl: pet['mediaUrl'],
                      mediaType: pet['mediaType'],
                      name: pet['name'],
                      breed: pet['breed'],
                      location: pet['distance'] != null
                          ? "${pet['location']} • ${pet['distance']} km"
                          : pet['location'],
                      onTap: () {
                        Get.toNamed('/pet-details', arguments: {
                          ...pet,
                          "id": pet['id'],
                          "ownerId": pet['ownerId'],
                        });
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),

      // 🔥 PREMIUM FAB
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          onPressed: () =>
              Get.to(() => const AddPetPage()),
          icon: const Icon(Icons.add),
          label: const Text(
            "Add Pet",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}