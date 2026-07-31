import 'dart:async';
import 'dart:io';

import 'package:aiscatty/models/chat/chat_controller.dart';
import 'package:aiscatty/services/notification_controller.dart';
import 'package:aiscatty/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key});
  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final controller = Get.find<ChatController>();
  final textController = TextEditingController();
  final picker = ImagePicker();
  bool sendingAttachment = false;
  final ScrollController _scrollController = ScrollController();
  final bool _autoScroll = true;

  String get chatId => Get.arguments['chatId']?.toString() ?? '';
  String get otherUserName => Get.arguments['otherUserName']?.toString() ?? 'User 🐾';

  @override
  void initState() {
    super.initState();
    // Mark chat as read when opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationController.to.markChatAsRead(chatId);
    });
  }

  @override
  void dispose() {
    textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || chatId.isEmpty) return const Scaffold(body: Center(child: Text('Conversation unavailable')));

    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primary, title: Row(children: [const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)), const SizedBox(width: 8), Text(otherUserName)])),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
        builder: (context, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatSnapshot.hasError) {
            return const Center(child: Text('Unable to load conversation.'));
          }

          if (!chatSnapshot.hasData || !chatSnapshot.data!.exists) {
            return const Center(child: Text('Conversation not found'));
          }

          final chatData = chatSnapshot.data!.data() as Map<String, dynamic>?;
          if (chatData == null) {
            return const Center(child: Text('Conversation data unavailable'));
          }

          final users = chatData['users'] as List<dynamic>? ?? [];

          // Verify the current user is a participant in this chat
          final isParticipant = users.contains(currentUser.uid);
          if (!isParticipant) {
            return const Center(child: Text('You are not a participant in this conversation'));
          }

          // Verify the chat is approved (active)
          final approved = chatData['approved'] == true;
          if (!approved) {
            return const Center(child: Text('This conversation is no longer active'));
          }

          return Column(children: [
            Expanded(child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').orderBy('createdAt', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return const Center(child: Text('Unable to load messages.'));
                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) return const Center(child: Text('Start conversation 💬'));
                
                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_autoScroll && _scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    return _MessageBubble(message: message, isMe: message['senderId'] == currentUser.uid);
                  },
                );
              },
            )),
            _composer(),
          ]);
        },
      ),
    );
  }

  Widget _composer() => SafeArea(top: false, child: Container(padding: const EdgeInsets.all(10), color: Colors.white, child: Row(children: [
    IconButton(onPressed: sendingAttachment ? null : _showAttachmentSheet, icon: sendingAttachment ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_circle_outline), color: AppColors.primary),
    Expanded(child: TextField(controller: textController, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Type message...', border: OutlineInputBorder()))),
    IconButton(icon: const Icon(Icons.send), color: AppColors.primary, onPressed: _sendText),
  ])));

  Future<void> _sendText() async {
    try { await controller.sendText(chatId, textController.text); textController.clear(); } catch (error) { _showError(error); }
  }

  void _showAttachmentSheet() => Get.bottomSheet(SafeArea(child: Container(color: Colors.white, padding: const EdgeInsets.all(20), child: Wrap(children: [
    ListTile(leading: const Icon(Icons.photo), title: const Text('Share photo'), onTap: () => _pickMedia(false)),
    ListTile(leading: const Icon(Icons.videocam), title: const Text('Share video'), onTap: () => _pickMedia(true)),
    ListTile(leading: const Icon(Icons.location_on), title: const Text('Share current location'), onTap: _shareLocation),
  ]))));

  Future<void> _pickMedia(bool video) async {
    Get.back();
    final XFile? picked = video ? await picker.pickVideo(source: ImageSource.gallery) : await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => sendingAttachment = true);
    try { await controller.sendMedia(chatId, File(picked.path), isVideo: video); } catch (error) { _showError(error); } finally { if (mounted) setState(() => sendingAttachment = false); }
  }

  Future<void> _shareLocation() async {
    Get.back(); setState(() => sendingAttachment = true);
    try { await controller.sendCurrentLocation(chatId); } catch (error) { _showError(error); } finally { if (mounted) setState(() => sendingAttachment = false); }
  }

  void _showError(Object error) => Get.snackbar('Could not send', error.toString().replaceFirst('Bad state: ', ''));
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});
  final Map<String, dynamic> message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final type = message['type']?.toString() ?? 'text';
    final child = switch (type) {
      'image' => ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(message['mediaUrl'] ?? '', width: 220, height: 180, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Padding(padding: EdgeInsets.all(12), child: Text('Photo unavailable')))),
      'video' => _VideoMessage(url: message['mediaUrl']?.toString() ?? ''),
      'location' => _LocationMessage(latitude: message['latitude'], longitude: message['longitude']),
      _ => Text(message['text']?.toString() ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black)),
    };
    return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: type == 'image' || type == 'video' ? const EdgeInsets.all(4) : const EdgeInsets.all(12), decoration: BoxDecoration(color: isMe ? AppColors.primary : Colors.grey[300], borderRadius: BorderRadius.circular(12)), child: child));
  }
}

class _LocationMessage extends StatelessWidget {
  const _LocationMessage({this.latitude, this.longitude});
  final dynamic latitude;
  final dynamic longitude;
  @override
  Widget build(BuildContext context) => SizedBox(width: 210, child: Row(children: [const Icon(Icons.location_on, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text('Location shared\n${latitude ?? '-'}, ${longitude ?? '-'}'))]));
}

class _VideoMessage extends StatefulWidget {
  const _VideoMessage({required this.url});
  final String url;
  @override
  State<_VideoMessage> createState() => _VideoMessageState();
}

class _VideoMessageState extends State<_VideoMessage> {
  late final VideoPlayerController player;
  @override
  void initState() { super.initState(); player = VideoPlayerController.networkUrl(Uri.parse(widget.url))..initialize().then((_) { if (mounted) setState(() {}); }); }
  @override
  void dispose() { player.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (!player.value.isInitialized) return const SizedBox(width: 220, height: 150, child: Center(child: CircularProgressIndicator()));
    return GestureDetector(onTap: () => setState(() => player.value.isPlaying ? player.pause() : player.play()), child: SizedBox(width: 220, child: AspectRatio(aspectRatio: player.value.aspectRatio, child: Stack(alignment: Alignment.center, children: [VideoPlayer(player), Icon(player.value.isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 48)]))));
  }
}
