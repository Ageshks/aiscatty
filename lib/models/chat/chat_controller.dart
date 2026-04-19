import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatController extends GetxController {
  final user = FirebaseAuth.instance.currentUser;

  /// 🔥 CREATE CHAT (ONE CHAT PER PET + USERS)
  Future<String> createChat(String otherUserId, String petId) async {
    final currentUserId = user!.uid;

    if (otherUserId.isEmpty) {
      throw Exception("Invalid ownerId");
    }

    // ✅ SAME CHAT ID FOR BOTH USERS
    final users = [currentUserId, otherUserId]..sort();
    final chatId = "${users[0]}_${users[1]}_$petId";

    final doc =
        FirebaseFirestore.instance.collection('chats').doc(chatId);

    final snapshot = await doc.get();

    if (!snapshot.exists) {
      await doc.set({
        "users": users,
        "petId": petId,
        "lastMessage": "",
        "updatedAt": FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  /// 🔥 SEND MESSAGE
  Future<void> sendMessage(String chatId, String text) async {
    if (text.trim().isEmpty) return;

    final msgRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages');

    await msgRef.add({
      "senderId": user!.uid,
      "text": text.trim(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .update({
      "lastMessage": text.trim(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }
}