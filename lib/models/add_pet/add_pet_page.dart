import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../utils/app_colors.dart';

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
  bool isVaccinated = false;

  final List<String> tags = ["Friendly", "Active", "Calm", "Playful"];
  List<String> selectedTags = [];

  double? lat;
  double? lng;

  File? selectedFile;
  String fileType = "image";

  final picker = ImagePicker();
  bool isUploading = false;

  /// 📍 LOCATION
  Future<void> getLocation() async {
    final permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      _showSnack("Location permission denied ❌");
      return;
    }

    final position = await Geolocator.getCurrentPosition();

    setState(() {
      lat = position.latitude;
      lng = position.longitude;
      locationController.text = "Location Selected ✅";
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

  /// 🎥 VIDEO
  Future<void> pickVideo() async {
    final picked = await picker.pickVideo(source: ImageSource.gallery);

    if (picked != null) {
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

    if (lat == null) return _showSnack("Select location 📍");
    if (selectedFile == null) return _showSnack("Upload media");

    try {
      String? fileUrl = await uploadFile();
      if (fileUrl == null) return _showSnack("Upload failed");

      await FirebaseFirestore.instance.collection('pets').add({
        "name": nameController.text.trim(),
        "breed": breedController.text.trim(),
        "description": descriptionController.text.trim(),
        "age": selectedAge,
        "gender": selectedGender,
        "vaccinated": isVaccinated,
        "tags": selectedTags,

        "location": locationController.text,
        "lat": lat,
        "lng": lng,
        "state": "Kerala",

        "mediaUrl": fileUrl,
        "mediaType": fileType,

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
                  ElevatedButton.icon(
                    onPressed: getLocation,
                    icon: const Icon(Icons.location_on),
                    label: const Text("Use Current Location"),
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