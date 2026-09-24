import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../services/location_service.dart';
import '../../widgets/pet_status_badge.dart';

class HomeController extends GetxController {
  var pets = [].obs;
  var isLoading = false.obs;

  /// Separate list for the "Pets Near You" page so this single controller
  /// can serve both screens without one overwriting the other's results.
  var nearbyPets = [].obs;
  var nearbyLoading = false.obs;
  final RxString nearbyError = ''.obs;

  /// "Pets Near You" is a strict radius search: only listings whose stored
  /// coordinates are within this distance of the user are shown.
  static const double nearbyRadiusKm = 10.0;

  /// Diagnostics for the Nearby empty state.
  final RxBool nearbyLocationMissing = false.obs;
  final RxInt nearbyMissingCoords = 0.obs;
  final RxInt nearbyBeyondRadius = 0.obs;

  /// Human readable reason when listings could not be loaded ('' = none).
  /// Surfaced in the UI so a failure is never silently shown as "no pets".
  final RxString loadError = ''.obs;

  /// Diagnostics used by the empty states so the user always knows *why*
  /// nothing is listed (no documents / pending / filters / error).
  final RxInt totalPetDocs = 0.obs;
  final RxInt ownPetCount = 0.obs;
  final RxInt pendingPetCount = 0.obs;
  final RxInt adoptedPetCount = 0.obs;

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

  /// Same, for the "Pets Near You" page (kept separate on purpose).
  List _allNearbyPets = [];

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

  /// True when a search query or any filter chip is active.
  bool get hasActiveFilters =>
      searchQuery.value.trim().isNotEmpty ||
      (speciesFilter.value != null && speciesFilter.value!.isNotEmpty) ||
      (genderFilter.value != null && genderFilter.value!.isNotEmpty) ||
      (ageFilter.value != null && ageFilter.value!.isNotEmpty) ||
      (statusFilter.value != null && statusFilter.value!.isNotEmpty);

  /// Title of the discovery empty state.
  ///
  /// Explains *why* nothing is listed instead of just showing an empty grid,
  /// which is what makes "I can't see the pets" impossible to diagnose.
  String get emptyStateTitle {
    if (loadError.value.isNotEmpty) return 'Could not load pets';
    if (hasActiveFilters) return 'No pets match your search';
    final district = activeDistrict.value;

    if (totalPetDocs.value == 0) {
      return 'No pets listed yet';
    }
    if (ownPetCount.value == totalPetDocs.value && ownPetCount.value > 0) {
      return 'Only your own listings so far';
    }
    if (adoptedPetCount.value == totalPetDocs.value) {
      return 'No available pets right now';
    }
    if (district.isEmpty) return 'No pets available in Kerala yet';
    return 'No pets available in $district yet';
  }

  /// Supporting line under [emptyStateTitle]. '' hides the line.
  String get emptyStateDetail {
    if (loadError.value.isNotEmpty) return loadError.value;
    if (hasActiveFilters) return 'Try clearing the search or the filters.';
    if (totalPetDocs.value == 0) {
      return 'No adoptable listings have been posted yet. Be the first to '
          'list a pet for adoption 🐾';
    }
    if (ownPetCount.value > 0 &&
        ownPetCount.value + adoptedPetCount.value >= totalPetDocs.value) {
      return 'Your own pets are listed in Profile → My Listings. Adoptable '
          'pets from other people will show up here.';
    }
    if (adoptedPetCount.value == totalPetDocs.value) {
      return 'Every pet here has already been adopted ❤️';
    }
    if (pendingPetCount.value > 0) {
      return '${pendingPetCount.value} pet(s) here have an adoption in '
          'progress. Switch the Status filter to "pending" to see them.';
    }
    return 'Try another district — tap the 📍 icon above.';
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

  /// Reads every pet document, keeps the adoptable ones and normalises them
  /// into UI friendly maps.
  ///
  /// [includeOwn] is false for the discovery feeds: a pet the user listed
  /// themselves belongs in Profile → My Listings, never in the public feed.
  ///
  /// One malformed document can never break the whole list, and nothing is
  /// assumed to exist: older listings may miss status/media/coordinates.
  Future<List> _fetchAvailablePets({bool includeOwn = false}) async {
    final currentUid = _auth.currentUser?.uid;

    // No server side orderBy: legacy documents without `createdAt` would be
    // silently dropped by Firestore. Ordering is done client side instead.
    final snapshot = await FirebaseFirestore.instance.collection('pets').get();

    final result = <Map<String, dynamic>>[];
    var mine = 0;
    var pending = 0;
    var adopted = 0;

    for (final doc in snapshot.docs) {
      try {
        final raw = doc.data();

        // Status is canonicalised so legacy casing ("Available", "Adoption
        // Pending", "Adopted ❤️") is understood everywhere downstream.
        final status = PetStatus.normalise(raw['status']);
        final isMine =
            currentUid != null && raw['ownerId']?.toString() == currentUid;

        // Permanently adopted pets are never part of discovery. They stay
        // visible to their owner in My Listings.
        if (status == PetStatus.adopted) {
          adopted++;
          continue;
        }

        if (status == PetStatus.pending) pending++;

        // 🚫 The owner's own listings stay out of the discovery feed —
        // they are managed from Profile → My Listings.
        if (isMine) {
          mine++;
          if (!includeOwn) continue;
        }

        final pet = _normalisePet(doc.id, raw);
        pet['isMine'] = isMine;
        result.add(pet);
      } catch (e) {
        debugPrint('⚠️ Skipping pet ${doc.id}: $e');
      }
    }

    totalPetDocs.value = snapshot.docs.length;
    ownPetCount.value = mine;
    pendingPetCount.value = pending;
    adoptedPetCount.value = adopted;

    debugPrint(
        '🐾 pets: ${snapshot.docs.length} doc(s) • ${result.length} usable • '
        '$mine own • $pending pending • $adopted adopted/sold');

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
    final wanted =
        (status == null || status.isEmpty) ? PetStatus.available : status;
    result = result.where(
        (p) => PetStatus.normalise(p['status']) == wanted);

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

  /// 🔥 LOAD NEARBY PETS — strict 10 km radius around the user
  ///
  /// Unlike Home (district based discovery), this page only returns pets whose
  /// stored coordinates are within [nearbyRadiusKm] of the current position,
  /// sorted nearest first. Pets without coordinates cannot be proven to be
  /// nearby, so they are counted (for the empty state) but not listed.
  ///
  /// Writes to [nearbyPets] so this screen never overwrites the Home feed
  /// (both share this one controller).
  Future<void> loadNearbyPets() async {
    nearbyLoading.value = true;
    nearbyError.value = '';
    nearbyLocationMissing.value = false;
    nearbyMissingCoords.value = 0;
    nearbyBeyondRadius.value = 0;

    try {
      // Ask for the permission here: this page is explicitly about "near you".
      await _resolveDistrict(requestPermission: true);

      final allPets = await _fetchAvailablePets();

      // A radius search is impossible without the user's own position.
      if (userLat == null || userLng == null) {
        nearbyLocationMissing.value = true;
        nearbyMissingCoords.value = allPets.length;
        _allNearbyPets = [];
        nearbyPets.value = [];
        debugPrint(
            '📍 Nearby: no user position — cannot apply the ${nearbyRadiusKm.toStringAsFixed(0)} km radius.');
        return;
      }

      final radiusMeters = nearbyRadiusKm * 1000;
      final withinRadius = <Map<String, dynamic>>[];
      var missingCoords = 0;
      var beyondRadius = 0;

      for (final pet in allPets) {
        final distanceMeters = _distanceTo(pet);

        if (distanceMeters == null) {
          // No usable coordinates → distance unknown, never claimed as near.
          missingCoords++;
          continue;
        }

        if (distanceMeters > radiusMeters) {
          beyondRadius++;
          continue;
        }

        pet['distanceKm'] = (distanceMeters / 1000).toStringAsFixed(1);
        withinRadius.add(pet);
      }

      // Nearest first.
      withinRadius.sort((a, b) => (_distanceTo(a) ?? double.maxFinite)
          .compareTo(_distanceTo(b) ?? double.maxFinite));

      _allNearbyPets = withinRadius;
      nearbyPets.value = withinRadius;
      nearbyMissingCoords.value = missingCoords;
      nearbyBeyondRadius.value = beyondRadius;

      debugPrint(
          '📍 Nearby: ${withinRadius.length} pet(s) within '
          '${nearbyRadiusKm.toStringAsFixed(0)} km • $beyondRadius beyond • '
          '$missingCoords without coordinates');
    } catch (e, st) {
      debugPrint('❌ Nearby Error: $e\n$st');
      nearbyError.value = _friendlyError(e);
      nearbyPets.value = [];
    } finally {
      nearbyLoading.value = false;
    }
  }

  /// Re-applies search/filters on the already fetched nearby listings.
  void applyNearbyFilters() {
    try {
      nearbyPets.value = _sortAndFilter(
        _allNearbyPets.isNotEmpty ? _allNearbyPets : nearbyPets.toList(),
      );
    } catch (e) {
      debugPrint('⚠️ Nearby local filter error: $e');
    }
  }

  /// 🔄 Refresh
  Future<void> refreshPets() async {
    await loadKeralaPets();
  }
}