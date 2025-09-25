import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/studio.dart';

class ApiService {
  // Change this to your backend URL
  // For local development: http://localhost:8080
  // For production: your deployed backend URL
  static const String baseUrl = 'http://localhost:8080/api';
  
  static const Duration timeoutDuration = Duration(seconds: 10);

  // Get all studios with optional filters
  static Future<List<Studio>> getStudios({
    String? location,
    double? maxPrice,
    String? search,
    bool availableOnly = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/studios').replace(
        queryParameters: {
          if (location != null && location.isNotEmpty) 'location': location,
          if (maxPrice != null) 'maxPrice': maxPrice.toString(),
          if (search != null && search.isNotEmpty) 'search': search,
          if (availableOnly) 'availableOnly': 'true',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Studio.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to load studios: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  // Get a specific studio by ID
  static Future<Studio> getStudioById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/studios/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return Studio.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('Studio not found', 404);
      } else {
        throw ApiException(
          'Failed to load studio: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  // Health check endpoint
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(timeoutDuration);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Create a new studio (for future use)
  static Future<Studio> createStudio(Studio studio) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/studios'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(studio.toJson()),
      ).timeout(timeoutDuration);

      if (response.statusCode == 201) {
        return Studio.fromJson(json.decode(response.body));
      } else {
        throw ApiException(
          'Failed to create studio: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
