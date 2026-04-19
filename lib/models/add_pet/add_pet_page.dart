import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
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
  final locationController = TextEditingController();

  double? lat;
  double? lng;

  File? selectedFile;
  String fileType = "image";

  final picker = ImagePicker();
  bool isUploading = false;

  /// 📍 GET LOCATION
  Future<void> getLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();

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

  /// 📸 PICK IMAGE
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedFile = File(picked.path);
        fileType = "image";
      });
    }
  }

  /// 🎥 PICK VIDEO
  Future<void> pickVideo() async {
    final picked = await picker.pickVideo(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedFile = File(picked.path);
        fileType = "video";
      });
    }
  }

  /// ☁️ CLOUDINARY UPLOAD (FIXED)
  Future<String?> uploadFile() async {
    try {
      setState(() => isUploading = true);

      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/dlwcgas2x/auto/upload",
      );

      var request = http.MultipartRequest("POST", url);

      // ⚠️ IMPORTANT: NO SPACES
      request.fields['upload_preset'] ='pets upload';

      request.files.add(
        await http.MultipartFile.fromPath('file', selectedFile!.path),
      );

      var response = await request.send();
      var res = await http.Response.fromStream(response);

      print("🔥 STATUS => ${res.statusCode}");
      print("🔥 RESPONSE => ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      print("❌ Cloudinary error: $e");
      return null;
    } finally {
      setState(() => isUploading = false);
    }
  }

  /// 🔥 SAVE PET (FINAL FIX)
  Future<void> savePet() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnack("User not logged in ❌");
      return;
    }

    if (nameController.text.isEmpty ||
        breedController.text.isEmpty) {
      _showSnack("Fill all fields");
      return;
    }

    if (lat == null || lng == null) {
      _showSnack("Select location 📍");
      return;
    }

    if (selectedFile == null) {
      _showSnack("Upload media 📸");
      return;
    }

    String? fileUrl = await uploadFile();

    if (fileUrl == null) {
      _showSnack("Upload failed ❌");
      return;
    }

    await FirebaseFirestore.instance.collection('pets').add({
      "name": nameController.text.trim(),
      "breed": breedController.text.trim(),
      "location": locationController.text,
      "lat": lat,
      "lng": lng,
      "state": "Kerala",
      "mediaUrl": fileUrl,
      "mediaType": fileType,

      // 🔥 CRITICAL FIX (CHAT WILL WORK NOW)
      "ownerId": user.uid,
      "ownerEmail": user.email,

      "createdAt": FieldValue.serverTimestamp(),
    });

    _showSnack("Pet Added 🐾");
    Get.back();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

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

            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Pet Name"),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: breedController,
              decoration: const InputDecoration(labelText: "Breed"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: locationController,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Location"),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: getLocation,
              icon: const Icon(Icons.location_on),
              label: const Text("Use Current Location"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Upload Image"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: pickVideo,
              child: const Text("Upload Video"),
            ),

            const SizedBox(height: 20),

            if (selectedFile != null)
              fileType == "image"
                  ? Image.file(selectedFile!, height: 150)
                  : const Text("Video Selected 🎥"),

            const SizedBox(height: 30),

            isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: savePet,
                    child: const Text("Submit"),
                  ),
          ],
        ),
      ),
    );
  }
}