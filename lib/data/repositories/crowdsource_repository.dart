import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/database/database_helper.dart';
import '../models/pending_submission_model.dart';

class CrowdsourceRepository {
  final DatabaseHelper _dbHelper;
  static const String apiBaseUrl = 'https://badil-api.cancellls.com/api/v1';

  CrowdsourceRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Enqueues submission to local SQLite first (offline resilience)
  Future<void> submitUnknownProduct({
    required String barcode,
    required String productName,
    String? brandName,
    required String suggestedStatus,
    String? suggestedAlternative,
    String? notes,
  }) async {
    final submission = PendingSubmissionModel(
      id: '${DateTime.now().millisecondsSinceEpoch}_$barcode',
      barcode: barcode,
      productName: productName,
      brandName: brandName,
      suggestedStatus: suggestedStatus,
      suggestedAlternative: suggestedAlternative,
      notes: notes,
      status: 'pending',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    // Save offline first
    await _dbHelper.insertPendingSubmission(submission);

    // Try background sync
    syncPendingSubmissions().ignore();
  }

  /// Synchronizes pending local submissions to the server
  Future<void> syncPendingSubmissions() async {
    try {
      final pending = await _dbHelper.getPendingSubmissions();
      if (pending.isEmpty) return;

      for (final item in pending) {
        try {
          final res = await http.post(
            Uri.parse('$apiBaseUrl/submissions'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(item.toMap()),
          ).timeout(const Duration(seconds: 5));

          if (res.statusCode == 200 || res.statusCode == 201) {
            await _dbHelper.markSubmissionSynced(item.id);
          }
        } catch (e) {
          if (kDebugMode) {
            print("Sync failed for item ${item.id}: $e");
          }
        }
      }
    } catch (_) {}
  }
}
