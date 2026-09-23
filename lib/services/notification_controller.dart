import 'dart:async';

import 'package:aiscatty/models/chat/chat_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// Manages unread badge counts for chat messages and adoption requests.
/// Shows red notification badges like WhatsApp on the bottom navigation bar.
class NotificationController extends GetxController {
  static NotificationController get to => Get.find();

  /// Unread chat message count
  final RxInt unreadChats = 0.obs;

  /// Unread adoption request count
  final RxInt unreadRequests = 0.obs;

  /// Total unread count (for combined badge)
  RxInt get totalUnread => RxInt(unreadChats.value + unreadRequests.value);

  StreamSubscription<QuerySnapshot>? _chatSub;
  StreamSubscription<QuerySnapshot>? _requestSub;

  @override
  void onInit() {
    super.onInit();
    _startListening();
  }

  void _startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;

    /// Single real-time listener over the user's chats. The per-user
    /// unreadCount map on each chat document is the source of truth, so no
    /// extra per-chat message queries are needed (avoids N+1 listeners).
    _chatSub = FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: uid)
        .where('approved', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Legacy chats may not have an unreadCount field yet -> treat as 0.
        final unreadData = data['unreadCount'] as Map<String, dynamic>? ?? {};
        final value = unreadData[uid] ?? 0;
        count += value is num ? value.toInt() : 0;
      }
      unreadChats.value = count;
    });

    /// Listen to pending adoption requests where user is the owner
    _requestSub = FirebaseFirestore.instance
        .collection('adoption_requests')
        .where('ownerId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      unreadRequests.value = snapshot.docs.length;
    });
  }

  /// Mark a chat as read by the current user (delegates to ChatController).
  Future<void> markChatAsRead(String chatId) async {
    try {
      await Get.find<ChatController>().markChatAsRead(chatId);
    } catch (_) {
      // Not signed in / controller unavailable — nothing to mark.
    }
  }

  @override
  void onClose() {
    _chatSub?.cancel();
    _requestSub?.cancel();
    super.onClose();
  }
}