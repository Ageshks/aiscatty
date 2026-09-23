import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../services/location_service.dart';

class HomeController extends GetxController {
  var pets = [].obs;
  var isLoading = false.obs;

  /// Human readable reason when listings could not be loaded ('' = none).
  /// Surfaced in the UI so a failure is never silently shown as "no pets".
  final RxString loadError = ''.obs;

  /// District currently driving discovery ('' = all Kerala).
  final RxString activeDistrict = ''.obs;

  /// Search query across name / breed / location / district.
  final RxString searchQuery = ''.obs;

  /// Active filters (null = no filter).
  final RxnString speciesFilter = RxnString(null);
  final RxnString genderFilter = RxnString(null);
  final RxnString ageFilter = RxnString(null);
  final RxnString statusFilter = RxnString(null);

  double? userLat;
  double? userLng;

  /// Last fetched listings (unfiltered) so search/filters can be applied
  /// client side without hammering Firestore on every keystroke.
  List _allPets = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    loadKeralaPets();
  }

  /// 🔥 LOAD PETS FOR THE USER'S DISTRICT (PRIMARY DISCOVERY)
  ///
  /// - Only pets with status == 'available' (adopted pets are hidden).
  /// - Same-district pets first, then closest, then newest.
  /// - Falls back gracefully: if no district is known, all Kerala pets are
  ///   shown and the UI offers a district picker.
  Future<void> loadKeralaPets() async {
    isLoading.value = true;
    loadError.value = '';
    try {
      await _resolveDistrict();

      final allPets = await _fetchAvailablePets();

      // Remember the raw result so search/filters run locally afterwards.
      _allPets = allPets;

      // A filtering/sorting problem must never hide the pets: fall back to
      // the unsorted list instead of showing an empty page.
      List sorted;
      try {
        sorted = _sortAndFilter(allPets);
      } catch (e) {
        debugPrint('⚠️ Filter error: $e');
        sorted = allPets;
      }

      pets.value = sorted;
    } catch (e, st) {
      debugPrint('❌ Home Error: $e\n$st');
      loadError.value = _friendlyError(e);
      pets.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Re-applies the search query and filters on the already fetched listings.
  ///
  /// Runs purely in memory: the UI reacts instantly while typing and no extra
  /// Firestore read is performed.
  void applyFilters() {
    try {
      pets.value = _sortAndFilter(
        _allPets.isNotEmpty ? _allPets : pets.toList(),
      );
    } catch (e) {
      debugPrint('⚠️ Local filter error: $e');
    }
  }

  /// Resolves the district + coordinates without ever throwing.
  Future<void> _resolveDistrict({bool requestPermission = false}) async {
    try {
      final location = Get.isRegistered<LocationService>()
          ? LocationService.to
          : Get.put(LocationService(), permanent: true);

      await location.detectDistrict(requestPermission: requestPermission);

      // The district can already be known (saved on the profile) while the
      // coordinates were never fetched — try a best effort refresh so the
      // distance labels still work.
      if (location.lastLatitude == null) {
        await location.refreshPosition();
      }

      activeDistrict.value = location.selectedDistrict.value;
      userLat = location.lastLatitude ?? userLat;
      userLng = location.lastLongitude ?? userLng;
    } catch (e) {
      debugPrint('📍 Location error: $e');
    }
  }

  /// Reads every pet document, keeps the adoptable ones that are not mine
  /// and normalises them into UI friendly maps.
  ///
  /// One malformed document can never break the whole list, and nothing is
  /// assumed to exist: older listings may miss status/media/coordinates.
  Future<List> _fetchAvailablePets() async {
    final currentUid = _auth.currentUser?.uid;

    // No server side orderBy: legacy documents without `createdAt` would be
    // silently dropped by Firestore. Ordering is done client side instead.
    final snapshot = await FirebaseFirestore.instance.collection('pets').get();

    final result = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      try {
        final raw = doc.data();

        // ❌ Skip my own pets
        if (currentUid != null && raw['ownerId'] == currentUid) continue;

        // Adopted pets are never shown. Pending pets are fetched but only
        // surfaced when the user explicitly filters for them, so the default
        // discovery view stays "available only".
        final status = raw['status']?.toString() ?? 'available';
        if (status == 'adopted' || status == 'sold') continue;

        result.add(_normalisePet(doc.id, raw));
      } catch (e) {
        debugPrint('⚠️ Skipping pet ${doc.id}: $e');
      }
    }

    if (snapshot.docs.isEmpty) {
      debugPrint('🐾 pets collection returned 0 documents — nothing to show.');
    } else {
      debugPrint(
          '🐾 pets: ${snapshot.docs.length} document(s), ${result.length} shown on discovery.');
    }

    return result;
  }

  /// Builds a UI friendly copy of a pet document.
  ///
  /// The grid requires non nullable strings, so media fields get safe
  /// fallbacks here instead of crashing the whole page when a listing has no
  /// image or uses an older field name.
  static Map<String, dynamic> _normalisePet(
      String id, Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);

    map['id'] = id;

    final mediaUrl = _mediaUrlOf(raw);
    map['mediaUrl'] = mediaUrl;
    map['mediaType'] = _mediaTypeOf(raw, mediaUrl);

    // Accept both new (`latitude`) and legacy (`lat`) keys, and both numeric
    // and string values.
    map['latitude'] = _toDouble(raw['latitude'] ?? raw['lat']);
    map['longitude'] = _toDouble(raw['longitude'] ?? raw['lng']);

    map['distanceKm'] = null;

    return map;
  }

  /// First usable image/video URL found on a pet document.
  static String _mediaUrlOf(Map<String, dynamic> raw) {
    for (final key in const [
      'mediaUrl',
      'imageUrl',
      'image',
      'photoUrl',
      'thumbnailUrl',
    ]) {
      final value = raw[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    // Structured media list support: [{type, url}, ...]
    final media = raw['media'];
    if (media is List && media.isNotEmpty) {
      final first = media.first;
      if (first is Map) {
        final value = first['url']?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }

    return '';
  }

  /// 'video' or 'image' — inferred from the URL when not declared.
  static String _mediaTypeOf(Map<String, dynamic> raw, String url) {
    final declared = raw['mediaType']?.toString().toLowerCase() ?? '';
    if (declared == 'video' || declared == 'image') return declared;

    final lower = url.toLowerCase();
    const videoHints = ['.mp4', '.mov', '.m4v', '.webm', '/video/upload/'];
    for (final hint in videoHints) {
      if (lower.contains(hint)) return 'video';
    }
    return 'image';
  }

  /// Safe number parsing: accepts num, numeric strings and null.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  /// Safe timestamp parsing for legacy/mixed createdAt formats.
  static DateTime? _createdAtOf(dynamic pet) {
    final value = pet['createdAt'] ?? pet['created_at'] ?? pet['timestamp'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Short, user friendly message for the empty state.
  static String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('permission-denied')) {
      return 'We could not load listings (permission denied). '
          'Please sign in again.';
    }
    if (text.contains('unavailable') ||
        text.contains('network') ||
        text.contains('SocketException')) {
      return 'Network problem — check your connection and try again.';
    }
    if (text.contains('failed-precondition') || text.contains('index')) {
      return 'Listings need a Firestore index. Please try again later.';
    }
    return 'Could not load pets right now. Please try again.';
  }

  /// Applies district priority, distance sort, search query and filters.
  List _sortAndFilter(List source) {
    Iterable result = source;

    // 🔍 SEARCH
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((pet) {
        final haystack = [
          pet['name'],
          pet['breed'],
          pet['location'],
          pet['district'],
        ].map((v) => v?.toString().toLowerCase() ?? '').join(' ');
        return haystack.contains(query);
      });
    }

    // 🎯 FILTERS (null = not filtered)
    final species = speciesFilter.value;
    if (species != null && species.isNotEmpty) {
      result = result.where((p) => (p['species'] ?? 'Dog').toString() == species);
    }
    final gender = genderFilter.value;
    if (gender != null && gender.isNotEmpty) {
      result = result.where((p) => (p['gender'] ?? '').toString() == gender);
    }
    final age = ageFilter.value;
    if (age != null && age.isNotEmpty) {
      result = result.where((p) => (p['age'] ?? '').toString() == age);
    }
    // 🔓 STATUS — defaults to "available" only (adopted pets are never shown
    // in discovery); the user can explicitly switch the filter to "pending".
    final status = statusFilter.value;
    final wanted = (status == null || status.isEmpty) ? 'available' : status;
    result = result.where(
        (p) => (p['status'] ?? 'available').toString() == wanted);

    final list = result.toList();

    // 📍 DISTRICT-FIRST + DISTANCE + NEWEST SORT
    try {
      list.sort(_comparePets);
    } catch (e) {
      // Never let a single bad document break discovery.
      debugPrint('⚠️ Sort error: $e');
    }

    // Attach approximate distance for display (internal use only).
    for (final pet in list) {
      try {
        final dist = _distanceTo(pet);
        pet['distanceKm'] =
            dist == null ? null : (dist / 1000).toStringAsFixed(1);
      } catch (e) {
        debugPrint('⚠️ Distance error: $e');
      }
    }

    return list;
  }

  /// Same district first, then closest, then most recently added.
  int _comparePets(dynamic a, dynamic b) {
    final district = activeDistrict.value;
    if (district.isNotEmpty) {
      final aSame = (a['district']?.toString() ?? '') == district;
      final bSame = (b['district']?.toString() ?? '') == district;
      if (aSame != bSame) return aSame ? -1 : 1;
    }

    final aDist = _distanceTo(a);
    final bDist = _distanceTo(b);
    if (aDist != null && bDist != null) {
      final byDistance = aDist.compareTo(bDist);
      if (byDistance != 0) return byDistance;
    } else if (aDist != null) {
      return -1;
    } else if (bDist != null) {
      return 1;
    }

    // Recently added first; legacy docs without a timestamp go last.
    final aCreated = _createdAtOf(a);
    final bCreated = _createdAtOf(b);
    if (aCreated != null && bCreated != null) {
      return bCreated.compareTo(aCreated);
    }
    if (aCreated != null) return -1;
    if (bCreated != null) return 1;
    return 0;
  }

  /// Approximate distance in metres, or null when it cannot be computed.
  ///
  /// Coordinates are parsed defensively — a legacy listing may store them as
  /// strings, which used to throw and empty the whole list.
  double? _distanceTo(dynamic pet) {
    final lat = _toDouble(pet['latitude']);
    final lng = _toDouble(pet['longitude']);
    if (userLat == null || userLng == null || lat == null || lng == null) {
      return null;
    }
    try {
      return Geolocator.distanceBetween(userLat!, userLng!, lat, lng);
    } catch (e) {
      return null;
    }
  }

  /// 🔥 LOAD NEARBY PETS (district page)
  Future<void> loadNearbyPets() async {
    isLoading.value = true;
    loadError.value = '';
    try {
      // Ask for the permission here: this page is explicitly about "near you".
      await _resolveDistrict(requestPermission: true);

      final allPets = await _fetchAvailablePets();

      // Pets with coordinates can show a distance. If none of them have
      // coordinates we still list the district pets instead of showing an
      // empty page.
      final withCoords = allPets
          .where((p) =>
              _toDouble(p['latitude']) != null &&
              _toDouble(p['longitude']) != null)
          .toList();

      final source = withCoords.isEmpty ? allPets : withCoords;
      _allPets = source;

      try {
        pets.value = _sortAndFilter(source);
      } catch (e) {
        debugPrint('⚠️ Nearby filter error: $e');
        pets.value = source;
      }
    } catch (e, st) {
      debugPrint('❌ Nearby Error: $e\n$st');
      loadError.value = _friendlyError(e);
      pets.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔄 Refresh
  Future<void> refreshPets() async {
    await loadKeralaPets();
  }
}