import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/location_service.dart';
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

        // ⏳ LOADING (only on the first load, so retries keep the list)
        if (controller.nearbyLoading.value && controller.nearbyPets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🐱 EMPTY / ERROR STATE
        if (controller.nearbyPets.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(
                    controller.nearbyError.value.isEmpty
                        ? Icons.pets
                        : Icons.cloud_off,
                    size: 72,
                    color: AppColors.primary.withOpacity(0.5),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    controller.nearbyError.value.isEmpty
                        ? "No pets nearby 🐾"
                        : "Could not load pets",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Obx(() {
                    final error = controller.nearbyError.value;
                    if (error.isNotEmpty) {
                      return Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      );
                    }
                    final district = controller.activeDistrict.value;
                    if (controller.nearbyLocationMissing.value) {
                      return Text(
                        "We could not get your current location. "
                          "Allow location access to see pets within 10 km.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      );
                    }
                    final beyond = controller.nearbyBeyondRadius.value;
                    final noCoords = controller.nearbyMissingCoords.value;
                    if (beyond == 0 && noCoords == 0) {
                      return Text(
                        district.isEmpty
                            ? "Select your district to see pets near you"
                            : "No pets listed in $district District yet",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      );
                    }
                    return Text(
                      [
                        if (beyond > 0)
                          '$beyond pet(s) are further than 10 km away.',
                        if (noCoords > 0)
                          '$noCoords listing(s) have no location yet.',
                      ].join(' '),
                      textAlign: TextAlign.center,
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

                  TextButton.icon(
                    onPressed: () async {
                      await LocationService.to.pickDistrictManually(context);
                      await controller.loadNearbyPets();
                    },
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text("Select your district"),
                  ),
                ],
              ),
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
                    "Adopt a pet within 10 km of you",
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 2),
                  Obx(() {
                    final district = controller.activeDistrict.value;
                    return Text(
                      district.isEmpty
                          ? "Allow location to see pets around you"
                          : "Showing pets within 10 km • $district District",
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
                itemCount: controller.nearbyPets.length,
                itemBuilder: (context, index) {
                  final pet = controller.nearbyPets[index];
                  final location = pet['location']?.toString() ?? '';
                  final petDistrict = pet['district']?.toString() ?? '';
                  final place = [
                    if (location.isNotEmpty) location,
                    if (petDistrict.isNotEmpty) petDistrict,
                  ].join(', ');
                  final distanceKm = pet['distanceKm']?.toString();

                  return PetCard(
                    petId: pet['id']?.toString() ?? '',
                    isMine: pet['isMine'] == true,
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