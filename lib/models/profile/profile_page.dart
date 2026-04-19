import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.lightBlue,

      body: Column(
        children: [

          // 🔥 Premium Header
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
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Colors.grey),
                ),
                const SizedBox(height: 10),

                // 🔥 Dynamic Email
                Text(
                  user?.email ?? "Guest User",
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

          // 🔥 Options Card
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

//                 _buildTile(
//   icon: Icons.favorite,
//   title: "Adoption Requests",
//   onTap: () {
//     Get.toNamed('/adoption-requests');
//   },
// ),

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

  // 🔥 Reusable Tile
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