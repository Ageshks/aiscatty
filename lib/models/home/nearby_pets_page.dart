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
          "Nearby Pets 📍",
          style: TextStyle(color: Colors.black),
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

                const Text(
                  "Try moving to a different area",
                  style: TextStyle(color: Colors.grey),
                ),

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

        // 🐾 PET LIST
        return ListView.builder(
          itemCount: controller.pets.length,
          itemBuilder: (context, index) {
            final pet = controller.pets[index];

            return PetCard(
              petId: pet['id'], // 🔥 MUST HAVE
              mediaUrl: pet['mediaUrl'],
              mediaType: pet['mediaType'],
              name: pet['name'],
              breed: pet['breed'],
              location:
                  "${pet['location']} • ${pet['distance']} km",
              onTap: () {
  Get.toNamed('/pet-details', arguments: {
    ...pet,
    "id": pet['id'],
    "ownerId": pet['ownerId'],
  });
},
            );
          },
        );
      }),
    );
  }
}