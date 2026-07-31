import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';

/// Background task name for checking new messages
const String checkMessagesTask = 'checkNewMessages';

/// Background task name for periodic check
const String periodicCheckTask = 'periodicMessageCheck';

/// Initialize the Flutter local notifications plugin
final FlutterLocalNotificationsPlugin localNotifications =
    FlutterLocalNotificationsPlugin();

/// Callback dispatched by Workmanager for background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Fallback for platforms without default options
      try {
        await Firebase.initializeApp();
      } catch (e) {
        return false;
      }
    }

    if (task == checkMessagesTask || task == periodicCheckTask) {
      await _checkForNewMessages();
    }
    return true;
  });
}

/// Check for new messages and show local notifications
Future<void> _checkForNewMessages() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;

  // Get all chats the user is part of
  final chatsSnapshot = await FirebaseFirestore.instance
      .collection('chats')
      .where('users', arrayContains: uid)
      .where('approved', isEqualTo: true)
      .get();

  for (var chatDoc in chatsSnapshot.docs) {
    final chatData = chatDoc.data();
    final lastReadAt = chatData['lastReadAt'] is Map
        ? (chatData['lastReadAt'] as Map<String, dynamic>)[uid]
        : null;
    final lastReadTimestamp = lastReadAt is Timestamp
        ? lastReadAt
        : Timestamp.fromDate(DateTime(2000));

    // Count unread messages from the other user
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatDoc.id)
        .collection('messages')
        .where('createdAt', isGreaterThan: lastReadTimestamp)
        .where('senderId', isNotEqualTo: uid)
        .get();

    if (messagesSnapshot.docs.isNotEmpty) {
      // Get the other user's name
      final users = List<String>.from(chatData['users'] ?? []);
      final otherUserId = users.where((id) => id != uid).firstOrNull ?? '';
      String senderName = 'New Message';

      if (otherUserId.isNotEmpty) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get();
          senderName = userDoc.data()?['name']?.toString() ?? 'New Message';
        } catch (_) {}
      }

      // Get the latest message text
      final latestMessage = messagesSnapshot.docs.last.data();
      final messageText = latestMessage['text']?.toString() ?? 'Sent a message';

      // Show local notification
      await _showLocalNotification(
        id: chatDoc.id.hashCode,
        title: senderName,
        body: messageText,
        payload: chatDoc.id,
      );
    }
  }
}

/// Show a local system notification
Future<void> _showLocalNotification({
  required int id,
  required String title,
  required String body,
  String? payload,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'chat_messages',
    'Chat Messages',
    channelDescription: 'Notifications for new chat messages',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
    icon: '@mipmap/ic_launcher',
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await localNotifications.show(
    id,
    title,
    body,
    details,
    payload: payload,
  );
}

/// Initialize local notifications
Future<void> initLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) async {
      // Handle notification tap - navigate to chat
      // This runs in foreground; for background taps, the OS handles it
    },
  );
}

/// Initialize Workmanager for periodic background tasks
Future<void> initWorkmanager() async {
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Register periodic task (minimum 15 minutes on Android)
  await Workmanager().registerPeriodicTask(
    periodicCheckTask,
    periodicCheckTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    backoffPolicy: BackoffPolicy.linear,
    backoffPolicyDelay: const Duration(minutes: 1),
  );
}