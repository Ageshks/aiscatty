import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/media_upload_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/kerala_districts.dart';

class AddPetPage extends StatefulWidget {
  const AddPetPage({super.key});

  @override
  State<AddPetPage> createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage> {
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  String? selectedAge;
  String? selectedGender;
  String? selectedSpecies = "Dog";
  bool isVaccinated = false;
  String status = "available";

  final List<String> tags = ["Friendly", "Active", "Calm", "Playful"];
  List<String> selectedTags = [];

  double? lat;
  double? lng;
  String district = "";
  final String state = "Kerala";

  File? selectedFile;
  String fileType = "image";

  /// 🎥 Optional status video (max 30s / 50MB), uploaded separately.
  File? statusVideoFile;
  Duration? statusVideoDuration;

  final picker = ImagePicker();
  bool isUploading = false;

  /// 📍 LOCATION — resolves coordinates and the Kerala district.
  Future<void> getLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack("Location permission denied ❌ — pick district manually");
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      setState(() {
        lat = position.latitude;
        lng = position.longitude;
        district = KeralaDistricts.detectDistrict(lat!, lng!);
        locationController.text =
            "Location Selected ✅ ($district)";
      });
    } catch (e) {
      _showSnack("Could not get location — pick district manually");
    }
  }

  /// 🏙️ MANUAL DISTRICT PICK (fallback when GPS is unavailable)
  Future<void> pickDistrict() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Select district 📍",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            for (final name in KeralaDistricts.names)
              ListTile(title: Text(name), onTap: () => Navigator.pop(context, name)),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        district = picked;
        locationController.text = locationController.text.isEmpty
            ? "District: $picked"
            : locationController.text;
      });
    }
  }

  /// 🎥 STATUS VIDEO — record or pick, then validate (≤30s, ≤50MB).
  Future<void> pickStatusVideo({required bool fromCamera}) async {
    final picked = await picker.pickVideo(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (picked == null) return;

    final file = File(picked.path);

    final error = await MediaUploadService.validateVideo(file);
    if (error != null) {
      _showSnack(error);
      return;
    }

    setState(() {
      statusVideoFile = file;
      statusVideoDuration = null;
    });
  }

  /// 📸 IMAGE
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedFile = File(picked.path);
        fileType = "image";
      });
    }
  }

  /// 🎥 VIDEO (main listing media)
  Future<void> pickVideo() async {
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );

    if (picked != null) {
      final file = File(picked.path);
      final error = await MediaUploadService.validateVideo(file);
      if (error != null) {
        _showSnack(error);
        return;
      }
      setState(() {
        selectedFile = File(picked.path);
        fileType = "video";
      });
    }
  }

  /// ☁️ UPLOAD
  Future<String?> uploadFile() async {
    try {
      setState(() => isUploading = true);

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/dlwcgas2x/auto/upload",
      );

      var request = http.MultipartRequest("POST", url);
      request.fields['upload_preset'] = 'pets upload';

      request.files.add(
        await http.MultipartFile.fromPath('file', selectedFile!.path),
      );

      var response = await request.send();
      var res = await http.Response.fromStream(response);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['secure_url'];
      }

      return null;
    } finally {
      setState(() => isUploading = false);
    }
  }

  /// 🔥 SAVE
  Future<void> savePet() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return _showSnack("Login required");

    if (nameController.text.isEmpty ||
        breedController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      return _showSnack("Fill all required fields");
    }

    if (district.isEmpty) {
      return _showSnack("Pick your district 📍 (use location or select manually)");
    }
    if (selectedFile == null) return _showSnack("Upload media");

    try {
      String? fileUrl = await uploadFile();
      if (fileUrl == null) return _showSnack("Upload failed ❌");

      // 🎥 Optional status video — only the URL is stored, never the binary.
      String? statusVideoUrl;
      if (statusVideoFile != null) {
        statusVideoUrl = await MediaUploadService.uploadFile(statusVideoFile!);
        if (statusVideoUrl == null) {
          _showSnack("Video upload failed — saving pet without video");
        }
      }

      await FirebaseFirestore.instance.collection('pets').add({
        "name": nameController.text.trim(),
        "breed": breedController.text.trim(),
        "description": descriptionController.text.trim(),
        "age": selectedAge,
        "gender": selectedGender,
        "vaccinated": isVaccinated,
        "tags": selectedTags,
        "species": selectedSpecies,

        "location": locationController.text,
        "district": district,
        "state": state,
        "latitude": lat,
        "longitude": lng,

        "mediaUrl": fileUrl,
        "mediaType": fileType,
        if (statusVideoUrl != null) "statusVideoUrl": statusVideoUrl,
        if (statusVideoDuration != null)
          "statusVideoDuration": statusVideoDuration!.inSeconds,

        "status": status,

        "ownerId": user.uid,
        "ownerEmail": user.email,

        "createdAt": FieldValue.serverTimestamp(),
      });

      // Show success dialog, then navigate back
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 16),
                Text("Pet Added 🐾",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Your pet has been listed successfully!"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Get.back();
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("❌ Save error: $e");
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error ❌"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// 🎯 TAG CHIP
  Widget buildTag(String tag) {
    final isSelected = selectedTags.contains(tag);

    return GestureDetector(
      onTap: () {
        setState(() {
          isSelected
              ? selectedTags.remove(tag)
              : selectedTags.add(tag);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  /// 🔥 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      appBar: AppBar(
        title: const Text("Add Pet"),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🧾 BASIC INFO CARD
            _card(
              child: Column(
                children: [
                  _input(nameController, "Pet Name"),
                  const SizedBox(height: 10),
                  _input(breedController, "Breed"),
                  const SizedBox(height: 10),
                  _input(descriptionController, "Description", maxLines: 3),
                ],
              ),
            ),

            /// 🎯 ATTRIBUTES
            _card(
              child: Column(
                children: [
                  DropdownButtonFormField(
                    hint: const Text("Species"),
                    initialValue: selectedSpecies,
                    items: ["Dog", "Cat", "Bird", "Rabbit", "Other"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedSpecies = val),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField(
                    hint: const Text("Select Age"),
                    items: ["Puppy", "Young", "Adult"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => selectedAge = val,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField(
                    hint: const Text("Gender"),
                    items: ["Male", "Female"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => selectedGender = val,
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: isVaccinated,
                    onChanged: (val) => setState(() => isVaccinated = val),
                    title: const Text("Vaccinated"),
                  ),
                ],
              ),
            ),

            /// 🏷️ TAGS
            _card(
              child: Wrap(
                children: tags.map(buildTag).toList(),
              ),
            ),

            /// 📍 LOCATION
            _card(
              child: Column(
                children: [
                  _input(locationController, "Location", readOnly: true),
                  const SizedBox(height: 10),
                  if (district.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "District: $district • State: $state",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: getLocation,
                          icon: const Icon(Icons.location_on),
                          label: const Text("Use Current Location"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: pickDistrict,
                        icon: const Icon(Icons.list),
                        label: const Text("Pick District"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// 🎥 STATUS VIDEO
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Add a short video of your pet 🎥",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const Text(
                    "Up to 30 seconds • max 50 MB",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => pickStatusVideo(fromCamera: true),
                          icon: const Icon(Icons.videocam),
                          label: const Text("Record"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => pickStatusVideo(fromCamera: false),
                          icon: const Icon(Icons.photo_library),
                          label: const Text("Gallery"),
                        ),
                      ),
                    ],
                  ),
                  if (statusVideoFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Video selected 🎥 (preview before upload)",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: "Remove video",
                            onPressed: () =>
                                setState(() => statusVideoFile = null),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            /// 📸 MEDIA
            _card(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: pickImage,
                    child: const Text("Upload Image"),
                  ),
                  ElevatedButton(
                    onPressed: pickVideo,
                    child: const Text("Upload Video"),
                  ),
                  if (selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: fileType == "image"
                          ? Image.file(selectedFile!, height: 120)
                          : const Text("Video Selected 🎥"),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: savePet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Submit"),
                  ),
          ],
        ),
      ),
    );
  }

  /// 🔹 UI HELPERS

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _input(TextEditingController controller, String label,
      {int maxLines = 1, bool readOnly = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}