import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pet_card.dart';
import '../../utils/app_colors.dart';
import 'home_controller.dart';

class NearbyPetsPage extends StatefulWidget {
  const NearbyPetsPage({super.key});

  @override
  State<NearbyPetsPage> createState() => _NearbyPetsPageState();
}

class _NearbyPetsPageState extends State<NearbyPetsPage> {
  final controller = Get.put(HomeController());

  @override
  void initState() {
    super.initState();

    // 🔥 Load once
    controller.loadNearbyPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,

      appBar: AppBar(
        backgroundColor: AppColors.lightGreen,
        elevation: 0,
        title: const Text(
          "Pets Near You 📍",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Obx(() {

        // ⏳ LOADING
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🐱 EMPTY STATE
        if (controller.pets.isEmpty) {
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
                  "No pets nearby 🐾",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Obx(() {
                  final district = controller.activeDistrict.value;
                  return Text(
                    district.isEmpty
                        ? "Select your district to see pets near you"
                        : "No pets listed in $district yet",
                    style: const TextStyle(color: Colors.grey),
                  );
                }),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    controller.loadNearbyPets();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        }

        // 🐾 PET LIST (header + list)
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Adopt a pet from your district",
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 2),
                  Obx(() {
                    final district = controller.activeDistrict.value;
                    return Text(
                      district.isEmpty
                          ? "Showing pets across Kerala"
                          : "Showing pets in $district District",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    );
                  }),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: controller.pets.length,
                itemBuilder: (context, index) {
                  final pet = controller.pets[index];
                  final location = pet['location']?.toString() ?? '';
                  final petDistrict = pet['district']?.toString() ?? '';
                  final place = [
                    if (location.isNotEmpty) location,
                    if (petDistrict.isNotEmpty) petDistrict,
                  ].join(', ');
                  final distanceKm = pet['distanceKm']?.toString();

                  return PetCard(
                    petId: pet['id']?.toString() ?? '',
                    mediaUrl: pet['mediaUrl']?.toString() ?? '',
                    mediaType: pet['mediaType']?.toString() ?? 'image',
                    name: pet['name']?.toString() ?? 'Pet',
                    breed: pet['breed']?.toString() ?? '',
                    location: distanceKm != null && distanceKm.isNotEmpty
                        ? "$place • $distanceKm km"
                        : place,
                    onTap: () {
                      Get.toNamed('/pet-details', arguments: {
                        ...pet,
                        "id": pet['id']?.toString() ?? '',
                        "ownerId": pet['ownerId']?.toString() ?? '',
                      });
                    },
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}