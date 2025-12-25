import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/service.dart';

class ServicesService {
  static final String baseUrl = dotenv.env['API_BASE_URL']!;

  // Helper: get token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Fetch all services
  static Future<List<Service>> getServices() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("User is not authenticated");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/api/services"), // Add /api prefix
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check if response has the expected structure
      if (data["status"] == "success" && data["data"] != null) {
        List services = data["data"];
        return services.map((s) => Service.fromJson(s)).toList();
      } else {
        throw Exception("Invalid response format");
      }
    } else {
      throw Exception(
        "Failed to load services: ${response.statusCode} ${response.reasonPhrase}",
      );
    }
  }

  static Future<Map<String, dynamic>> getServiceDetails(int id) async {
    final token = await _getToken();

    if (token == null) {
      throw Exception("User is not authenticated");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/api/services/$id"), // Add /api prefix
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Check if response has the expected structure
      if (responseData["status"] == "success" && responseData["data"] != null) {
        return responseData["data"];
      } else {
        throw Exception("Invalid response format");
      }
    } else {
      throw Exception(
        "Failed to fetch service: ${response.statusCode} ${response.reasonPhrase}",
      );
    }
  }
}
