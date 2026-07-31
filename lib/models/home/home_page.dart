import 'package:aiscatty/models/home/banner_slider.dart';
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

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator());
        }

        return CustomScrollView(
          slivers: [

            // 🔥 PREMIUM HEADER
            SliverToBoxAdapter(
              child: GestureDetector(
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
                  child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                      Icon(Icons.pets, color: Colors.white, size: 42),
                    ],
                  ),
                ),
              ),
            ),

            // 🔥 BANNER SLIDER
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: BannerSlider(),
              ),
            ),

            // 🔥 SECTION TITLE
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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
            ),

            // 🔥 PET GRID (2 COLUMNS)
            controller.pets.isEmpty
                ? const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        "No pets available 🐾",
                        style: TextStyle(
                          color: AppColors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final pet = controller.pets[index];
                          return PetCard(
                            compact: true,
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
                          );
                        },
                        childCount: controller.pets.length,
                      ),
                    ),
                  ),
          ],
        );
      }),

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
