import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/app_colors.dart';

class AdoptionRequestsPage extends StatelessWidget {
  const AdoptionRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    /// 🔥 SAFE USER CHECK (FIXES NULL CRASH)
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login again")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightGreen,

      appBar: AppBar(
        title: const Text("Adoption Requests ❤️"),
        backgroundColor: AppColors.primary,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adoption_requests')
            .where('ownerId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          /// ⏳ LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ❌ ERROR
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          final requests = snapshot.data?.docs ?? [];

          /// 🐾 EMPTY
          if (requests.isEmpty) {
            return const Center(
              child: Text("No requests yet 🐾"),
            );
          }

          /// 📋 LIST
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];

              /// 🔥 SAFE MAP PARSE
              final data = doc.data() as Map<String, dynamic>? ?? {};

              final petName =
                  data['petName']?.toString() ?? "Pet";
              final requesterEmail =
                  data['requesterEmail']?.toString() ?? "Unknown";
              final status =
                  data['status']?.toString() ?? "pending";

              return Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),

                  title: Text(petName),

                  subtitle:
                      Text("Requested by: $requesterEmail"),

                  trailing: _statusWidget(status, doc.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 🔥 STATUS UI (SAFE)
  Widget _statusWidget(String status, String docId) {

    if (status == "approved") {
      return const Text(
        "Approved ✅",
        style: TextStyle(color: Colors.green),
      );
    }

    if (status == "rejected") {
      return const Text(
        "Rejected ❌",
        style: TextStyle(color: Colors.red),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [

        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: () => _updateStatus(docId, "approved"),
        ),

        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => _updateStatus(docId, "rejected"),
        ),
      ],
    );
  }

  /// 🔥 UPDATE STATUS
  void _updateStatus(String docId, String status) {
    FirebaseFirestore.instance
        .collection('adoption_requests')
        .doc(docId)
        .update({
      "status": status,
    });
  }
}