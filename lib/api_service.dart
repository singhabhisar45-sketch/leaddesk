// ──────────────────────────────────────────────────────────────────────────────
// api_service.dart — All HTTP calls to the Go backend
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lead.dart';

// Custom exception so we can show the server's error message in the UI
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  // Change this to your deployed backend URL before going live
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://13.232.215.204:8080');

  static String? jwtToken;

  static Map<String, String> get _headers {
    final h = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (jwtToken != null) {
      h['Authorization'] = 'Bearer $jwtToken';
    }
    return h;
  }

  // Authenticate admin and store token
  static Future<void> login(String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        jwtToken = json['data']['token'] as String;
        return;
      }
      throw ApiException(json['error'] as String? ?? 'Login failed');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Cannot connect to server.');
    }
  }

  // Submit a new lead (called from the landing page form)
  static Future<Lead> submitLead({
    required String name,
    required String email,
    required String budgetRange,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/leads'),
        headers: _headers,
        body: jsonEncode({
          'name': name, 'email': email,
          'budget_range': budgetRange, 'message': message,
        }),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 201) {
        return Lead.fromJson(json['data'] as Map<String, dynamic>);
      }
      throw ApiException(json['error'] as String? ?? 'Something went wrong');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Cannot connect to server. Is the backend running?');
    }
  }

  // Get all leads (with optional search filter) — called from admin page
  static Future<List<Lead>> getLeads({String search = ''}) async {
    final query = search.isNotEmpty ? '?search=${Uri.encodeComponent(search)}' : '';
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/leads$query'),
        headers: _headers,
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final list = json['data'] as List<dynamic>;
        return list.map((e) => Lead.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw ApiException(json['error'] as String? ?? 'Failed to load leads');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Cannot connect to server. Is the backend running?');
    }
  }

  // Update a lead's status — called when admin taps the status chip
  static Future<Lead> updateStatus(int id, String newStatus) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/leads/$id/status'),
        headers: _headers,
        body: jsonEncode({'status': newStatus}),
      );
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return Lead.fromJson(json['data'] as Map<String, dynamic>);
      }
      throw ApiException(json['error'] as String? ?? 'Failed to update status');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Cannot connect to server.');
    }
  }
}
