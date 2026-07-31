import 'package:aiscatty/models/chat/chat_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/app_colors.dart';

class AdoptionRequestsPage extends StatelessWidget {
  const AdoptionRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Please login again')));
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      appBar: AppBar(title: const Text('Adoption Requests ❤️'), backgroundColor: AppColors.primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('adoption_requests').where('ownerId', isEqualTo: user.uid).orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load requests',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMsg.contains('index')
                          ? 'The database index is being set up.\nPlease try again in a few minutes.'
                          : errorMsg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
          final requests = snapshot.data?.docs ?? [];
          if (requests.isEmpty) return const Center(child: Text('No requests yet 🐾'));
          return ListView.builder(itemCount: requests.length, itemBuilder: (context, index) {
            final doc = requests[index];
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return Container(margin: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(data['petName']?.toString() ?? 'Pet'),
              subtitle: Text('Requested by: ${data['requesterEmail']?.toString() ?? 'Unknown'}'),
              trailing: _statusWidget(doc.id, data),
            ));
          });
        },
      ),
    );
  }

  Widget _statusWidget(String requestId, Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? 'pending';
    if (status == 'approved') {
      return TextButton.icon(icon: const Icon(Icons.chat), label: const Text('Chat'), onPressed: () {
        final requesterId = data['requesterId']?.toString() ?? '';
        if (requesterId.isNotEmpty) {
          FirebaseFirestore.instance.collection('users').doc(requesterId).get().then((userDoc) {
            final userName = (userDoc.data()?['name']?.toString()) ?? 'User';
            Get.toNamed('/chat-detail', arguments: {'chatId': data['chatId'], 'otherUserName': userName});
          });
        } else {
          Get.toNamed('/chat-detail', arguments: {'chatId': data['chatId'], 'otherUserName': 'User'});
        }
      });
    }
    if (status == 'rejected') return const Text('Rejected', style: TextStyle(color: Colors.red));
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: const Icon(Icons.check, color: Colors.green), tooltip: 'Approve and enable chat', onPressed: () => _approve(requestId, data)),
      IconButton(icon: const Icon(Icons.close, color: Colors.red), tooltip: 'Decline request', onPressed: () => _reject(requestId)),
    ]);
  }

  Future<void> _approve(String requestId, Map<String, dynamic> data) async {
    try {
      final chatId = await Get.find<ChatController>().approveRequest(requestId);
      Get.snackbar('Request approved', 'Chat is now available to both users.');
      final requesterId = data['requesterId']?.toString() ?? '';
      if (requesterId.isNotEmpty) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(requesterId).get();
        final userName = (userDoc.data()?['name']?.toString()) ?? 'User';
        Get.toNamed('/chat-detail', arguments: {'chatId': chatId, 'otherUserName': userName});
      } else {
        Get.toNamed('/chat-detail', arguments: {'chatId': chatId, 'otherUserName': 'User'});
      }
    } catch (error) { Get.snackbar('Could not approve request', error.toString()); }
  }

  Future<void> _reject(String requestId) async {
    try { await Get.find<ChatController>().rejectRequest(requestId); } catch (error) { Get.snackbar('Could not decline request', error.toString()); }
  }
}
