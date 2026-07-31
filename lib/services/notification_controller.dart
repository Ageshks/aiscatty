import 'dart:async';

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

    /// Listen to all chats the user is part of
    _chatSub = FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: uid)
        .where('approved', isEqualTo: true)
        .snapshots()
        .listen((snapshot) async {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lastReadAt = data['lastReadAt'] is Map
            ? (data['lastReadAt'] as Map<String, dynamic>)[uid]
            : null;
        final lastReadTimestamp = lastReadAt is Timestamp
            ? lastReadAt
            : Timestamp.fromDate(DateTime(2000));

        // Count messages after lastReadAt
        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(doc.id)
            .collection('messages')
            .where('createdAt', isGreaterThan: lastReadTimestamp)
            .where('senderId', isNotEqualTo: uid)
            .get();

        count += messagesSnapshot.docs.length;
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

  /// Mark a chat as read by the current user
  Future<void> markChatAsRead(String chatId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .update({
      'lastReadAt.${user.uid}': FieldValue.serverTimestamp(),
    });
  }

  @override
  void onClose() {
    _chatSub?.cancel();
    _requestSub?.cancel();
    super.onClose();
  }
}