import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../network/insforge_client.dart';
import '../models/district.dart';
import '../models/service_category.dart';

class DatabaseService {
  final InsForgeClient _client = InsForgeClient();

  /// Inserts a single record into a table
  Future<bool> insertRecord(String tableName, Map<String, dynamic> data) async {
    try {
      // InsForge requires an array even for a single record insert
      final response = await _client.post(
        '/api/database/records/$tableName',
        body: [data],
        requireAuth: true, // Requires the user to be logged in (has accessToken)
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('DB Insert Error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception during insertRecord: $e');
      return false;
    }
  }

  /// Updates records matching a specific column condition
  Future<bool> updateRecordByColumn(String tableName, String columnName, String value, Map<String, dynamic> data) async {
    try {
      final response = await _client.patch(
        '/api/database/records/$tableName?$columnName=eq.$value',
        body: data,
        requireAuth: true,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('DB Update Error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception during updateRecordByColumn: $e');
      return false;
    }
  }

  /// Fetches active districts from database
  Future<List<District>> fetchActiveDistricts() async {
    try {
      final response = await _client.get('/api/database/records/districts?is_active=eq.true&order=name.asc', requireAuth: true);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => District.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Exception fetching districts: $e');
    }
    return [];
  }

  /// Fetches active service categories from database
  Future<List<ServiceCategory>> fetchActiveCategories() async {
    try {
      final response = await _client.get('/api/database/records/service_categories?is_active=eq.true&order=name.asc', requireAuth: true);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => ServiceCategory.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Exception fetching categories: $e');
    }
    return [];
  }

  /// Fetches registered category IDs for a technician
  Future<List<int>> fetchTechnicianCategoryIds(String userId) async {
    try {
      final response = await _client.get('/api/database/records/technician_categories?technician_id=eq.$userId', requireAuth: true);
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => item['category_id'] as int).toList();
      }
    } catch (e) {
      debugPrint('Exception fetching technician categories: $e');
    }
    return [];
  }
}
