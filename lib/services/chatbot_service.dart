import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ChatbotService {
  /// Query the chatbot API with a user message
  /// Returns a map with: success, reply, service, worker, error
  static Future<Map<String, dynamic>> query(String message) async {
    try {
      // Use the same base URL as ApiService
      final baseUrl = ApiService.baseUrl;
      
      final response = await http.post(
        Uri.parse("$baseUrl/api/chatbot/query"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message.trim()}),
      );

      print('Chatbot API response status: ${response.statusCode}');
      print('Chatbot API response body: ${response.body}');

      if (response.statusCode != 200) {
        try {
          final decoded = jsonDecode(response.body);
          return {
            'success': false,
            'error': decoded['error'] ?? 'Server error occurred',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Failed to connect to server',
          };
        }
      }

      final decoded = jsonDecode(response.body);
      return decoded;
    } catch (e) {
      print('Chatbot service error: $e');
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}

