import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Please sign in to continue.');
    return uid;
  }

  /// An adoption request is the only way a prospective adopter can start
  /// contact. A chat is deliberately not created at this point.
  ///
  /// Requests are only allowed while the pet is 'available'.
  Future<String> requestAdoption({
    required String ownerId,
    required String petId,
    required String petName,
  }) async {
    final requesterId = _uid;
    if (ownerId.isEmpty || ownerId == requesterId) {
      throw StateError('You cannot request adoption for your own pet.');
    }

    // Block requests for pending/adopted pets (missing field = available).
    try {
      final petDoc = await _firestore.collection('pets').doc(petId).get();
      final status = petDoc.data()?['status']?.toString() ?? 'available';
      if (status == 'adopted') {
        throw StateError('This pet has already been adopted ❤️');
      }
      if (status == 'pending') {
        throw StateError('Adoption is already in progress for this pet.');
      }
    } catch (e) {
      if (e is StateError) rethrow;
      // Firestore hiccup — allow the request to proceed rather than block.
    }

    final requestId = '${petId}_${requesterId}';
    final ref = _firestore.collection('adoption_requests').doc(requestId);
    final existing = await ref.get();
    if (!existing.exists) {
      await ref.set({
        'petId': petId,
        'petName': petName,
        'ownerId': ownerId,
        'requesterId': requesterId,
        'requesterEmail': FirebaseAuth.instance.currentUser?.email ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return requestId;
  }

  /// Called by the pet owner. It atomically marks the request approved and
  /// creates the sole conversation for this pet and these two users.
  final _uuid = const Uuid();

  Future<String> approveRequest(String requestId) async {
    final requestRef = _firestore.collection('adoption_requests').doc(requestId);
    return _firestore.runTransaction((transaction) async {
      final request = await transaction.get(requestRef);
      if (!request.exists) throw StateError('Adoption request was not found.');
      final data = request.data()!;
      if (data['ownerId'] != _uid) throw StateError('Only the pet owner can approve this request.');

      final requesterId = data['requesterId'] as String;
      final petId = data['petId'] as String;
      final users = [_uid, requesterId]..sort();
      // Use a random UUID for chatId to prevent unauthorized access
      // by guessing predictable chat IDs like "userA_userB_petId"
      final chatId = _uuid.v4();
      final chatRef = _firestore.collection('chats').doc(chatId);

      transaction.set(chatRef, {
        'users': users,
        'petId': petId,
        'petName': data['petName'] ?? 'Pet',
        'adoptionRequestId': requestId,
        'approved': true,
        'lastMessage': 'Adoption request approved. You can now chat.',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'ownerId': _uid,
        'requesterId': requesterId,
        // Per-user unread counters. Each participant has their own count so
        // two users can have different unread numbers.
        'unreadCount': {
          _uid: 0,
          requesterId: 0,
        },
      }, SetOptions(merge: true));
      transaction.update(requestRef, {
        'status': 'approved',
        'chatId': chatId,
        'updatedAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
      });
      // Approval moves the pet to 'pending' — NOT adopted. The owner must
      // explicitly confirm the adoption afterwards.
      transaction.update(_firestore.collection('pets').doc(petId), {
        'status': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return chatId;
    });
  }

  /// Owner confirms the adoption. This is the only step that permanently
  /// marks the pet as adopted and closes further requests.
  Future<void> confirmAdoption({
    required String petId,
    required String requestId,
  }) async {
    if (petId.isEmpty) throw StateError('Pet information missing.');
    final requestRef = _firestore.collection('adoption_requests').doc(requestId);
    final request = await requestRef.get();
    if (!request.exists) throw StateError('Adoption request was not found.');
    if (request.data()?['ownerId'] != _uid) {
      throw StateError('Only the pet owner can confirm the adoption.');
    }

    final batch = _firestore.batch();
    batch.update(requestRef, {
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('pets').doc(petId), {
      'status': 'adopted',
      'adoptedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> rejectRequest(String requestId) {
    return _firestore.collection('adoption_requests').doc(requestId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendText(String chatId, String text) {
    return _sendMessage(chatId, {
      'type': 'text',
      'text': text.trim(),
    });
  }

  Future<void> sendMedia(String chatId, File file, {required bool isVideo}) async {
    final url = await _uploadToCloudinary(file);
    await _sendMessage(chatId, {
      'type': isVideo ? 'video' : 'image',
      'mediaUrl': url,
      'text': isVideo ? 'Video' : 'Photo',
    });
  }

  /// Uses the same unsigned Cloudinary preset as pet-listing uploads.
  Future<String> _uploadToCloudinary(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/dlwcgas2x/auto/upload'),
    )
      ..fields['upload_preset'] = 'pets upload'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Cloudinary upload failed (${response.statusCode}).');
    }
    final url = (jsonDecode(response.body) as Map<String, dynamic>)['secure_url']?.toString();
    if (url == null || url.isEmpty) throw StateError('Cloudinary did not return a media URL.');
    return url;
  }

  Future<void> sendCurrentLocation(String chatId) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission is required to share your location.');
    }
    final position = await Geolocator.getCurrentPosition();
    await _sendMessage(chatId, {
      'type': 'location',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'text': 'Shared a location',
    });
  }

  Future<void> _sendMessage(String chatId, Map<String, dynamic> message) async {
    if (message['type'] == 'text' && (message['text'] as String).isEmpty) return;
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chat = await chatRef.get();
    final data = chat.data();
    if (!chat.exists || data == null || !(data['users'] as List).contains(_uid)) {
      throw StateError('This conversation is not available.');
    }

    // The other participant is the receiver of this message.
    final users = List<String>.from(data['users'] as List);
    final receiverId = users.firstWhere((id) => id != _uid, orElse: () => '');

    // Atomically write the message and bump the receiver's unread counter.
    // The sender's unread count is never increased.
    final batch = _firestore.batch();
    batch.set(chatRef.collection('messages').doc(), {
      ...message,
      'senderId': _uid,
      'receiverId': receiverId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(chatRef, {
      'lastMessage': message['text'],
      'updatedAt': FieldValue.serverTimestamp(),
      // Dot notation creates the unreadCount map if it does not exist yet
      // (e.g. chats created before this field was introduced).
      if (receiverId.isNotEmpty) 'unreadCount.$receiverId': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// Marks the conversation as read for the currently logged-in user only.
  ///
  /// - Resets this user's entry in the chat's unreadCount map to 0.
  /// - Marks only messages received by this user (senderId != me) as read.
  ///   Messages sent by the current user are never modified.
  Future<void> markChatAsRead(String chatId) async {
    final uid = _uid;
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chat = await chatRef.get();
    if (!chat.exists) return;

    final batch = _firestore.batch();

    // Reset only my unread counter; the other participant's count is untouched.
    batch.update(chatRef, {'unreadCount.$uid': 0});

    // Mark unread messages that I received as read.
    final unreadReceived = await chatRef
        .collection('messages')
        .where('senderId', isNotEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in unreadReceived.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
