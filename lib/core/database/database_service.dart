import 'dart:convert';
import '../network/insforge_client.dart';

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
        print('DB Insert Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception during insertRecord: $e');
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
        print('DB Update Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception during updateRecordByColumn: $e');
      return false;
    }
  }
}
