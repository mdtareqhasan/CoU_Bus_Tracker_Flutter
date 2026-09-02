import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'constants.dart';

class ApiService {
  static String get baseUrl => ApiConstants.baseUrl;

  // --- Singleton Pattern ---
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Common Headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // --- GET Request ---
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');

    if (kDebugMode) {
      print('🚀 GET Request: $url');
    }

    try {
      final response = await http.get(url, headers: _headers);
      _logResponse(response);
      return response;
    } catch (e) {
      if (kDebugMode) print('❌ GET Error: $e');
      rethrow;
    }
  }

  // --- POST Request ---
  Future<http.Response> post(String endpoint, dynamic body) async {
    final url = Uri.parse('$baseUrl$endpoint');

    if (kDebugMode) {
      print('🚀 POST Request: $url');
      print('📦 Body: ${jsonEncode(body)}');
    }

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );
      _logResponse(response);
      return response;
    } catch (e) {
      if (kDebugMode) print('❌ POST Error: $e');
      rethrow;
    }
  }

  // --- Helper Methods ---
  void _logResponse(http.Response response) {
    if (kDebugMode) {
      print('📥 Response [${response.statusCode}]: ${response.body}');
    }
  }
}
