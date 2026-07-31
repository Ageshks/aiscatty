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
  Future<String> requestAdoption({
    required String ownerId,
    required String petId,
    required String petName,
  }) async {
    final requesterId = _uid;
    if (ownerId.isEmpty || ownerId == requesterId) {
      throw StateError('You cannot request adoption for your own pet.');
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
      }, SetOptions(merge: true));
      transaction.update(requestRef, {
        'status': 'approved',
        'chatId': chatId,
        'updatedAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
      });
      return chatId;
    });
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

    await chatRef.collection('messages').add({
      ...message,
      'senderId': _uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await chatRef.update({
      'lastMessage': message['text'],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
