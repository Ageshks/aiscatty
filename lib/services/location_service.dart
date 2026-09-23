import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/kerala_districts.dart';

/// Central place for everything district related.
///
/// Discovery flow: location permission -> position -> district. When the
/// district cannot be detected the user picks one manually and the choice is
/// remembered on their Firestore profile (users/{uid}.district).
class LocationService extends GetxService {
  /// Safe accessor — registers the service on first use so the UI can never
  /// crash with "LocationService not found".
  static LocationService get to {
    if (Get.isRegistered<LocationService>()) return Get.find<LocationService>();
    return Get.put(LocationService(), permanent: true);
  }

  /// District used for discovery. Falls back to Thrissur until determined.
  final RxString selectedDistrict = ''.obs;

  /// True once the district was chosen by the user (not auto-detected).
  final RxBool manuallySelected = false.obs;

  /// True while detecting the current position.
  final RxBool detecting = false.obs;

  /// Last known coordinates, used internally for distance calculations only.
  double? lastLatitude;
  double? lastLongitude;

  @override
  void onInit() {
    super.onInit();
    _loadFromProfile();
  }

  /// Restores a previously saved manual district choice from the profile.
  Future<void> _loadFromProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final district = doc.data()?['district']?.toString() ?? '';
      if (district.isNotEmpty && KeralaDistricts.names.contains(district)) {
        selectedDistrict.value = district;
        manuallySelected.value = true;
      }
    } catch (_) {
      // Profile may not exist yet — manual selection still works.
    }
  }

  /// Attempts the full detection flow. Never throws.
  ///
  /// Returns true when a district was determined (auto or already saved).
  Future<bool> detectDistrict({bool requestPermission = false}) async {
    if (selectedDistrict.value.isNotEmpty) return true;
    detecting.value = true;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return false;
      }

      // A GPS fix may never arrive (indoors, emulator, provider disabled).
      // The timeout guarantees the discovery flow always finishes.
      final position = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 10));

      lastLatitude = position.latitude;
      lastLongitude = position.longitude;
      selectedDistrict.value =
          KeralaDistricts.detectDistrict(position.latitude, position.longitude);
      return true;
    } catch (_) {
      return false;
    } finally {
      detecting.value = false;
    }
  }

  /// Shows the district picker and stores the selection on the profile.
  Future<void> pickDistrictManually(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select your district 📍',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            for (final name in KeralaDistricts.names)
              ListTile(
                title: Text(name),
                trailing: name == selectedDistrict.value
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(context, name),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await setDistrict(picked, manual: true);
  }

  /// Applies a district choice and persists it on the user profile.
  Future<void> setDistrict(String district, {bool manual = false}) async {
    selectedDistrict.value = district;
    manuallySelected.value = manual;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'district': district,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Non-fatal: the in-memory choice is still used for this session.
    }
  }

  /// Best-effort location refresh for distance calculations. Never throws.
  Future<void> refreshPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 10));
      lastLatitude = position.latitude;
      lastLongitude = position.longitude;
    } catch (_) {}
  }
}
