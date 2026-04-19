import 'package:aiscatty/models/chat/chat_controller.dart';
import 'package:aiscatty/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class ChatDetailPage extends StatelessWidget {
  ChatDetailPage({super.key});

  final controller = Get.find<ChatController>(); // ✅ FIXED
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatId = Get.arguments['chatId'];
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        backgroundColor: AppColors.primary,
      ),

      body: Column(
        children: [

          /// 💬 MESSAGES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUser!.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.primary
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ✍️ INPUT
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration:
                        const InputDecoration(hintText: "Type message..."),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    await controller.sendMessage(
                      chatId,
                      textController.text,
                    );
                    textController.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}