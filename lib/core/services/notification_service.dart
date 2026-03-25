import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../api/chat_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _chatService = ChatService();
  Timer? _timer;
  int _lastUnreadCount = 0;
  bool _initialized = false;

  final unreadCountNotifier = ValueNotifier<int>(0);

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _checkUnread());
  }

  void stopPolling() => _timer?.cancel();

  Future<void> _checkUnread() async {
    try {
      final count = await _chatService.getUnreadCount();
      unreadCountNotifier.value = count;
      if (count > _lastUnreadCount && _initialized) {
        final newMsgs = count - _lastUnreadCount;
        await _plugin.show(
          0,
          'New Message',
          'You have $newMsgs new message${newMsgs > 1 ? 's' : ''}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_channel', 'Chat Messages',
              channelDescription: 'Notifications for new chat messages',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
      _lastUnreadCount = count;
    } catch (_) {}
  }

  void resetCount() => _lastUnreadCount = 0;
}
