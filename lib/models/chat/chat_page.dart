import 'package:aiscatty/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightGreen,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          "Messages 💬",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: user.uid)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No chats yet 💬",
                style: TextStyle(fontSize: 14),
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final data = chats[index];

              final users = List<String>.from(data['users'] ?? []);

              final otherUser = users.firstWhere(
                (id) => id != user.uid,
                orElse: () => "Unknown",
              );

              final displayName =
                  otherUser == "Unknown"
                      ? "User"
                      : otherUser.substring(0, 6);

              final lastMessage =
                  data['lastMessage']?.toString() ?? "";

              return GestureDetector(
                onTap: () {
                  Get.toNamed('/chat-detail', arguments: {
                    "chatId": data.id,
                  });
                },

                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),

                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),

                  child: Row(
                    children: [

                      /// 🟢 AVATAR
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.blue,
                        child: Text(
                          displayName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// 💬 TEXT AREA
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            /// NAME
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 4),

                            /// LAST MESSAGE
                            Text(
                              lastMessage.isEmpty
                                  ? "Start conversation..."
                                  : lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// ➡️ ARROW
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}