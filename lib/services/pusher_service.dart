import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:skillbox/models/notification.dart';
import 'package:skillbox/models/chat.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;
  PusherService._internal();

  PusherChannelsFlutter? pusher;
  bool _isInitialized = false;
  String? _userId;

  /// 🔔 Notifications callback (already existed)
  Function(NotificationModel)? onNotificationReceived;

  /// 💬 Added: Chat message callback
  Function(ChatMessage)? onMessageReceived;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print('❌ No token found, cannot initialize Pusher');
        return;
      }

      // Decode JWT
      _userId = _getUserIdFromToken(token);
      if (_userId == null) {
        print('❌ Could not extract user ID from token');
        return;
      }

      pusher = PusherChannelsFlutter.getInstance();

      await pusher!.init(
        apiKey: dotenv.env['PUSHER_APP_KEY']!,
        cluster: dotenv.env['PUSHER_CLUSTER']!,
        useTLS: true,
        onConnectionStateChange: onConnectionStateChange,
        onError: onError,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onEvent: onEvent,
        onSubscriptionError: onSubscriptionError,
        onDecryptionFailure: onDecryptionFailure,
        onMemberAdded: onMemberAdded,
        onMemberRemoved: onMemberRemoved,
        onAuthorizer: onAuthorizer,
      );

      /// 🔔 Subscribe to user notifications
      await pusher!.subscribe(channelName: 'private-user-$_userId');

      await pusher!.connect();

      _isInitialized = true;
      print('✅ Pusher initialized for user: $_userId');
    } catch (e) {
      print('❌ Error initializing Pusher: $e');
    }
  }

  /// Decode JWT payload
  String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      final map = json.decode(decoded);

      return map['data']?['id']?.toString();
    } catch (e) {
      print('Error decoding token: $e');
      return null;
    }
  }

  /// Authorization for private channels
  dynamic onAuthorizer(String channelName, String socketId, dynamic options) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return null;

      final response = await http.post(
        Uri.parse(dotenv.env['PUSHER_AUTH_ENDPOINT']!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'socket_id': socketId,
          'channel_name': channelName,
        }),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body['auth'] != null && body['shared_secret'] != null) {
          return {
            'auth': body['auth'],
            'shared_secret': body['shared_secret'],
          };
        }
      }

      print('❌ Pusher auth error: ${response.body}');
      return null;
    } catch (e) {
      print('❌ Auth error: $e');
      return null;
    }
  }

  /// 🔥 ALL EVENTS COME HERE
  void onEvent(PusherEvent event) {
    print('📩 Event: ${event.eventName}');
    print('📦 Payload: ${event.data}');
    print('📡 Channel: ${event.channelName}');

    /// 🔔 USER NOTIFICATION EVENT
    if (event.eventName == 'notification.received') {
      try {
        final data = json.decode(event.data);
        final notification = NotificationModel.fromJson(data);

        onNotificationReceived?.call(notification);
      } catch (e) {
        print('❌ Notification parse error: $e');
      }
    }

    /// 💬 CHAT MESSAGE EVENT
    if (event.eventName == 'chat.message') {
      try {
        final raw = json.decode(event.data);
        final message = ChatMessage.fromJson(raw);

        print("💬 Real-time message received: ${message.text}");

        onMessageReceived?.call(message);
      } catch (e) {
        print('❌ Chat parse error: $e');
      }
    }
  }

  // --- CALLBACKS ---
  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print('✅ Subscribed to: $channelName');
  }

  void onSubscriptionError(String message, dynamic e) {
    print('❌ Subscription error: $message');
  }

  void onDecryptionFailure(String event, String reason) {
    print('❌ Decryption failure: $event - $reason');
  }

  void onMemberAdded(String channelName, PusherMember member) {
    print('👤 Member added: ${member.userId}');
  }

  void onMemberRemoved(String channelName, PusherMember member) {
    print('👤 Member removed: ${member.userId}');
  }

  void onConnectionStateChange(dynamic currentState, dynamic previousState) {
    print('🔄 Connection: $currentState');
  }

  void onError(String message, int? code, dynamic e) {
    print('❌ Pusher error: $message - $code');
  }

  Future<void> disconnect() async {
    if (_userId != null) {
      await pusher?.unsubscribe(channelName: 'private-user-$_userId');
    }
    await pusher?.disconnect();
    _isInitialized = false;
  }

  // 🔥 CALL THIS WHEN OPENING A CHAT SCREEN
  Future<void> subscribeToChatChannel(int user1, int user2) async {
    if (!_isInitialized) await initialize();

    int a = user1 < user2 ? user1 : user2;
    int b = user1 < user2 ? user2 : user1;

    String channelName = "private-chat-$a-$b";

    print("📡 Subscribing to chat: $channelName");

    await pusher!.subscribe(channelName: channelName);
  }
}
