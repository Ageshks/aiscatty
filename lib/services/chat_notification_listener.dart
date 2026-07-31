import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// WhatsApp-style in-app notification popups for new messages
/// and adoption requests.
class ChatNotificationListener {
  static StreamSubscription<QuerySnapshot>? _chatSub;
  static StreamSubscription<QuerySnapshot>? _requestSub;
  static Map<String, String> _lastKnownMessages = {};

  static void init() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    /// Listen for new messages by watching the messages subcollection directly.
    /// This ensures we only get notified for messages where the sender is NOT
    /// the current user, preventing self-notifications.
    _chatSub = FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: uid)
        .where('approved', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified ||
            change.type == DocumentChangeType.added) {
          final chatData = change.doc.data();
          if (chatData == null) continue;

          final chatId = change.doc.id;
          final lastMessage = chatData['lastMessage']?.toString() ?? '';

          // Check if this is a genuinely new message (not the initial load)
          final previousMessage = _lastKnownMessages[chatId] ?? '';
          if (previousMessage.isNotEmpty && previousMessage != lastMessage && lastMessage.isNotEmpty) {
            // Fetch the latest message to check who sent it
            FirebaseFirestore.instance
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .orderBy('createdAt', descending: true)
                .limit(1)
                .get()
                .then((msgSnapshot) {
              if (msgSnapshot.docs.isNotEmpty) {
                final latestMsg = msgSnapshot.docs.first.data();
                final senderId = latestMsg['senderId']?.toString() ?? '';

                // Only show notification if the message was sent by someone else
                if (senderId != uid) {
                  // Get the other user's name from the users list
                  final users = List<String>.from(chatData['users'] ?? []);
                  final otherUserId = users.where((id) => id != uid).firstOrNull ?? '';

                  if (otherUserId.isNotEmpty) {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUserId)
                        .get()
                        .then((userDoc) {
                      final senderName = userDoc.data()?['name']?.toString() ?? 'New Message';
                      _showChatNotification(senderName, lastMessage);
                    }).catchError((_) {
                      _showChatNotification('New Message', lastMessage);
                    });
                  } else {
                    _showChatNotification('New Message', lastMessage);
                  }
                }
              }
            }).catchError((_) {});
          }
          // Store the current message for next comparison
          _lastKnownMessages[chatId] = lastMessage;
        }
      }
    });

    /// Listen for new adoption requests
    _requestSub = FirebaseFirestore.instance
        .collection('adoption_requests')
        .where('ownerId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;
          final petName = data['petName']?.toString() ?? 'a pet';
          _showAdoptionNotification(petName);
        }
      }
    });
  }

  static void _showChatNotification(String senderName, String message) {
    Get.snackbar(
      senderName,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      duration: const Duration(seconds: 4),
      icon: const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0xFF2ECC71),
        child: Text(
          '💬',
          style: TextStyle(fontSize: 16),
        ),
      ),
      mainButton: TextButton(
        onPressed: () {
          Get.back(); // close snackbar
          Get.toNamed('/home'); // go to main navigation
        },
        child: const Text(
          'View',
          style: TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static void _showAdoptionNotification(String petName) {
    Get.snackbar(
      "📋 New Adoption Request",
      "Someone wants to adopt $petName",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: Colors.black87,
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      duration: const Duration(seconds: 5),
      icon: const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.orange,
        child: Text(
          '📋',
          style: TextStyle(fontSize: 16),
        ),
      ),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          Get.toNamed('/adoption-requests');
        },
        child: const Text(
          'View',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static void dispose() {
    _chatSub?.cancel();
    _requestSub?.cancel();
    _lastKnownMessages.clear();
  }
}
