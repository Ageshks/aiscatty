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
            .where('approved', isEqualTo: true)
            .orderBy('updatedAt', descending: true)
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

          /// ❌ EMPTY
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No chats yet 💬"),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final doc = chats[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              /// Get the other user's ID from the users list
              final users = List<String>.from(data['users'] ?? []);
              final otherUserId = users.where((id) => id != user.uid).firstOrNull ?? '';

              /// ✅ LAST MESSAGE SAFE
              final lastMessage =
                  data['lastMessage']?.toString() ?? "";

              return FutureBuilder<DocumentSnapshot>(
                future: otherUserId.isNotEmpty
                    ? FirebaseFirestore.instance.collection('users').doc(otherUserId).get()
                    : null,
                builder: (context, userSnapshot) {
                  final otherUserData = userSnapshot.data?.data() as Map<String, dynamic>?;
                  final otherUserName = otherUserData?['name']?.toString() ?? (otherUserId.isNotEmpty ? 'User' : 'Unknown');
                  final avatarLetter = otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?';

                  /// Get unread count for this chat
                  final lastReadAt = data['lastReadAt'] is Map
                      ? (data['lastReadAt'] as Map<String, dynamic>)[user.uid]
                      : null;
                  final lastReadTimestamp = lastReadAt is Timestamp
                      ? lastReadAt
                      : Timestamp.fromDate(DateTime(2000));

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(doc.id)
                        .collection('messages')
                        .where('createdAt', isGreaterThan: lastReadTimestamp)
                        .where('senderId', isNotEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, msgSnapshot) {
                      final unreadCount = msgSnapshot.data?.docs.length ?? 0;

                      return GestureDetector(
                        onTap: () {
                          Get.toNamed('/chat-detail', arguments: {
                            "chatId": doc.id,
                            "otherUserName": otherUserName,
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

                              /// 👤 AVATAR WITH UNREAD BADGE
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.blue,
                                    child: Text(
                                      avatarLetter,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        child: Text(
                                          unreadCount > 99
                                              ? '99+'
                                              : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(width: 12),

                              /// 💬 TEXT AREA
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [

                                    /// 👤 OTHER USER NAME (MAIN TITLE)
                                    Text(
                                      otherUserName,
                                      style: TextStyle(
                                        fontWeight: unreadCount > 0
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    /// 💬 LAST MESSAGE
                                    Text(
                                      lastMessage.isEmpty
                                          ? "Start conversation..."
                                          : lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                        fontWeight: unreadCount > 0
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// Unread count badge on the right
                              if (unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    unreadCount > 99
                                        ? '99+'
                                        : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

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
              );
            },
          );
        },
      ),
    );
  }
}
