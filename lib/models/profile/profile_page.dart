import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../utils/app_colors.dart';
import 'privacy_policy_page.dart';
import 'terms_conditions_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final picker = ImagePicker();

  bool isUploading = false;

  /// 📸 PICK IMAGE
  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      File file = File(picked.path);

      String? url = await uploadToCloudinary(file);

      if (url != null) {
        await user?.updatePhotoURL(url);
        await user?.reload();

        setState(() {});
        Get.snackbar("Success", "Profile updated 🎉");
      } else {
        Get.snackbar("Error", "Upload failed ❌");
      }
    }
  }

  /// ☁️ UPLOAD TO CLOUDINARY
  Future<String?> uploadToCloudinary(File file) async {
    try {
      setState(() => isUploading = true);

      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/dlwcgas2x/image/upload",
      );

      var request = http.MultipartRequest("POST", uri);

      // ⚠️ IMPORTANT: use your preset name correctly
      request.fields['upload_preset'] = 'pets upload';

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      var response = await request.send();
      var res = await http.Response.fromStream(response);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['secure_url'];
      } else {
        print("❌ Upload failed: ${res.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error: $e");
      return null;
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.lightBlue,

      body: Column(
        children: [

          /// 🔥 HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 80, bottom: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.blue],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [

                /// 🖼️ PROFILE IMAGE
                Stack(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: currentUser?.photoURL != null
                            ? NetworkImage(currentUser!.photoURL!)
                            : null,
                        child: currentUser?.photoURL == null
                            ? const Icon(Icons.person,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: pickImage,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primary,
                          child: isUploading
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.edit,
                                  size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// 📧 EMAIL
                Text(
                  currentUser?.email ?? "Guest User",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  "Pet Lover 🐾",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// 🔥 OPTIONS CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                )
              ],
            ),
            child: Column(
              children: [

                _buildTile(
                  icon: Icons.pets,
                  title: "My Listings",
                  onTap: () {
                    Get.toNamed('/my-listings');
                  },
                ),

                _buildTile(
                  icon: Icons.volunteer_activism,
                  title: "Adoption Requests",
                  onTap: () => Get.toNamed('/adoption-requests'),
                ),

                _buildTile(
                  icon: Icons.privacy_tip,
                  title: "Privacy Policy",
                  onTap: () => Get.to(() => const PrivacyPolicyPage()),
                ),

                _buildTile(
                  icon: Icons.description,
                  title: "Terms & Conditions",
                  onTap: () => Get.to(() => const TermsConditionsPage()),
                ),

                _buildTile(
                  icon: Icons.logout,
                  title: "Logout",
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Get.offAllNamed('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 REUSABLE TILE
  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
