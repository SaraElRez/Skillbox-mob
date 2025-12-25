import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat.dart';
import '../models/conversation.dart';
import 'api_service.dart';

class ChatService {
  static String get baseUrl => '${ApiService.baseUrl}/api/chat';

  // ---------- PUSHER SETUP ----------
  static final PusherChannelsFlutter _pusher =
      PusherChannelsFlutter.getInstance();

  static bool _isConnected = false;

  /// Streams for UI to listen in real-time
  static final StreamController<ChatMessage> messageStream =
      StreamController.broadcast();

  static final StreamController<Conversation> conversationStream =
      StreamController.broadcast();

  static final StreamController<int> readStream = StreamController.broadcast();

  // ---------- TOKEN ----------
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers({
    bool isMultipart = false,
  }) async {
    final token = await _getToken();
    return {
      if (!isMultipart) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // =====================================================
  // 🔥 INITIALIZE PUSHER REAL-TIME
  // =====================================================
  static Future<void> initializePusher(int userId) async {
    if (_isConnected) return;

    try {
      await _pusher.init(
        apiKey: dotenv.env['PUSHER_APP_KEY']!,
        cluster: dotenv.env['PUSHER_CLUSTER']!,
        onEvent: (event) {
          print("📡 Pusher Event: ${event.eventName}");
          print(event.data);

          final data = jsonDecode(event.data);

          switch (event.eventName) {
            case "new-message":
              messageStream.add(ChatMessage.fromJson(data));
              break;

            case "new-conversation":
              conversationStream.add(Conversation.fromJson(data));
              break;

            case "message-read":
              readStream.add(data['conversation_id']);
              break;
          }
        },
      );

      await _pusher.subscribe(channelName: "private-user-$userId");

      await _pusher.connect();

      _isConnected = true;
      print("✅ Pusher Connected");
    } catch (e) {
      print("❌ Pusher Error: $e");
    }
  }

  // =====================================================
  // 🔥 API CALLS
  // =====================================================

  static Future<List<Conversation>> getConversations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations'),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['conversations'] as List)
          .map((j) => Conversation.fromJson(j))
          .toList();
    }

    throw Exception("Failed to load conversations");
  }

  static Future<Map<String, dynamic>> startConversation(int otherUserId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/start'),
      headers: await _headers(),
      body: jsonEncode({'other_user_id': otherUserId}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return {
        'conversation': Conversation.fromJson(data['conversation']),
        'other_user': data['other_user'],
      };
    }

    throw Exception("Failed to start conversation");
  }

  static Future<List<ChatMessage>> getMessages(
    int conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/messages/$conversationId?limit=$limit&offset=$offset',
      ),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['messages'] as List)
          .map((j) => ChatMessage.fromJson(j))
          .toList();
    }

    throw Exception("Failed to load messages");
  }

  static Future<ChatMessage> sendMessage({
    required int conversationId,
    String? text,
    File? attachmentFile,
  }) async {
    if (attachmentFile != null) {
      return _sendMessageWithFile(
        conversationId: conversationId,
        text: text,
        file: attachmentFile,
      );
    }

    final response = await http.post(
      Uri.parse('$baseUrl/send'),
      headers: await _headers(),
      body: jsonEncode({'conversation_id': conversationId, 'text': text ?? ""}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return ChatMessage.fromJson(data['message']);
    }

    throw Exception("Failed to send message");
  }

  static Future<ChatMessage> _sendMessageWithFile({
    required int conversationId,
    String? text,
    required File file,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        throw Exception('No authentication token');
      }

      final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/send"));

      // Set headers
      request.headers['Authorization'] = "Bearer $token";
      request.headers['Accept'] = "application/json";

      // Add fields
      request.fields['conversation_id'] = conversationId.toString();
      if (text != null && text.isNotEmpty) {
        request.fields['text'] = text;
      }

      // Add file with proper content type detection
      final filename = file.path.split('/').last;
      final mimeType = _getMimeType(filename);

      print('📤 Uploading file: $filename');
      print('📤 MIME type: $mimeType');
      print('📤 File size: ${await file.length()} bytes');

      request.files.add(
        await http.MultipartFile.fromPath(
          'attachment',
          file.path,
          filename: filename,
        ),
      );

      print('📤 Sending request to: ${request.url}');

      // Send request
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ChatMessage.fromJson(data['message']);
      }

      throw Exception(data['error'] ?? 'Failed to send file');
    } catch (e) {
      print('❌ Error sending file: $e');
      throw Exception('Failed to send file: $e');
    }
  }

  // Helper to get MIME type from filename
  static String _getMimeType(String filename) {
    final extension = filename.split('.').last.toLowerCase();

    final mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  static Future<void> markAsRead(int conversationId) async {
    await http.post(
      Uri.parse('$baseUrl/mark-read/$conversationId'),
      headers: await _headers(),
    );
  }

  static Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/unread-count'),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['unread_count'];
    }

    return 0;
  }
}
