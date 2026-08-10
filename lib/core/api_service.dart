import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // --- Configuration ---
  static const String _wifiBaseUrl = "http:// 192.168.1.176:8080/api";
  static const String _usbBaseUrl = "http://localhost:8080/api";

  // State to track which URL to use
  static bool useWifi = false;

  // Dynamic Base URL getter
  static String get baseUrl => useWifi ? _wifiBaseUrl : _usbBaseUrl;

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

  /// Toggle between USB (localhost) and Wifi (IP) debugging
  static void toggleDebugMode(bool wifi) {
    useWifi = wifi;
    if (kDebugMode) {
      print('🔧 ApiService BaseURL switched to: $baseUrl');
    }
  }
}
