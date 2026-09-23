import 'package:aiscatty/models/home/banner_slider.dart';
import 'package:aiscatty/models/home/nearby_pets_page.dart';
import 'package:aiscatty/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/pet_card.dart';
import '../../utils/app_colors.dart';
import '../add_pet/add_pet_page.dart';
import 'home_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final controller = Get.put(HomeController());
  final searchController = TextEditingController();

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
        // Only the very first load blocks the screen. Later reloads keep the
        // listings visible (the pull-to-refresh indicator shows progress).
        if (controller.isLoading.value && controller.pets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // 📍 District header text — falls back to Kerala when unknown.
        final district = controller.activeDistrict.value;
        final districtLabel = district.isEmpty
            ? "Pets Available in Kerala"
            : "Pets Available in $district";

        return RefreshIndicator(
          onRefresh: controller.refreshPets,
          child: CustomScrollView(
            slivers: [

              // 🔥 PREMIUM HEADER
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () async {
                    await Get.to(() => const NearbyPetsPage());
                    // The Nearby page reuses this controller, so refresh the
                    // district-wide discovery list when coming back.
                    controller.refreshPets();
                  },
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

            // 🔥 DISTRICT TITLE + CHANGE / FILTER ACTIONS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(() => Text(
                            districtLabel,
                            style: const TextStyle(
                              color: AppColors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          )),
                    ),
                    // 📍 Change district (also shown when detection failed)
                    IconButton(
                      tooltip: "Select your district",
                      icon: const Icon(Icons.location_on_outlined,
                          color: AppColors.black),
                      onPressed: () async {
                        await LocationService.to
                            .pickDistrictManually(context);
                        controller.refreshPets();
                      },
                    ),
                    // 🎯 Filters
                    IconButton(
                      tooltip: "Filters",
                      icon: const Icon(Icons.tune, color: AppColors.black),
                      onPressed: () => _showFilterSheet(context),
                    ),
                  ],
                ),
              ),
            ),

            // 🔍 SEARCH BAR
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search name, breed, place…",
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    controller.searchQuery.value = value;
                    // Instant, in-memory filtering — no Firestore round trip.
                    controller.applyFilters();
                  },
                ),
              ),
            ),

            // 🔥 PET GRID (2 COLUMNS)
            controller.pets.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              controller.loadError.value.isEmpty
                                  ? Icons.pets
                                  : Icons.cloud_off,
                              size: 48,
                              color: AppColors.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              controller.loadError.value.isEmpty
                                  ? "No pets available here yet 🐾"
                                  : controller.loadError.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.black,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (controller.loadError.value.isNotEmpty)
                              TextButton.icon(
                                onPressed: controller.refreshPets,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Try again"),
                              ),
                            TextButton.icon(
                              onPressed: () async {
                                await LocationService.to
                                    .pickDistrictManually(context);
                                await controller.refreshPets();
                              },
                              icon: const Icon(Icons.location_on_outlined),
                              label: const Text("Select your district"),
                            ),
                          ],
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
                          final location = pet['location']?.toString() ?? '';
                          final petDistrict = pet['district']?.toString() ?? '';
                          final place = [
                            if (location.isNotEmpty) location,
                            if (petDistrict.isNotEmpty) petDistrict,
                          ].join(', ');
                          final distanceKm = pet['distanceKm']?.toString();
                          return PetCard(
                            compact: true,
                            petId: pet['id']?.toString() ?? '',
                            mediaUrl: pet['mediaUrl']?.toString() ?? '',
                            mediaType: pet['mediaType']?.toString() ?? '',
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
                        childCount: controller.pets.length,
                      ),
                    ),
                  ),
          ],
        ),
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

  /// 🎯 FILTER SHEET — species / gender / age / status
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            String? species = controller.speciesFilter.value;
            String? gender = controller.genderFilter.value;
            String? age = controller.ageFilter.value;
            String? status = controller.statusFilter.value;

            Widget chips(String label, List<String> options, String? selected,
                ValueChanged<String?> onSelected) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: options
                          .map((o) => ChoiceChip(
                                label: Text(o),
                                selected: selected == o,
                                selectedColor: AppColors.primary,
                                onSelected: (v) =>
                                    setState(() => onSelected(v ? o : null)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Filter pets 🎯',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                chips('Animal', ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'],
                    species, (v) => species = v),
                chips('Gender', ['Male', 'Female'], gender, (v) => gender = v),
                chips('Age', ['Puppy', 'Young', 'Adult'], age, (v) => age = v),
                chips('Status', ['available', 'pending'], status,
                    (v) => status = v),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            controller.speciesFilter.value = null;
                            controller.genderFilter.value = null;
                            controller.ageFilter.value = null;
                            controller.statusFilter.value = null;
                            Navigator.pop(context);
                            controller.applyFilters();
                          },
                          child: const Text('Clear all'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary),
                          onPressed: () {
                            controller.speciesFilter.value = species;
                            controller.genderFilter.value = gender;
                            controller.ageFilter.value = age;
                            controller.statusFilter.value = status;
                            Navigator.pop(context);
                            controller.applyFilters();
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
