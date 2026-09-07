import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/ist_utils.dart';

/// Google Sheets spreadsheet IDs for each register
class RegisterSheetIds {
  static const String cutting = '1qx_bcwA7_gQRQWgeacZlA2OCVeHcL8QtZRZ2aH30cUg';
  static const String production = '1WgpFKOSazlyrLGnsp4vDqmWV-xzbeyiJ';
  static const String lay = '1Yp7Mqy0xPrdub4cxGgyiAuydidPwsgcY-wRgUmGrTU4';
  static const String fabric = '1Ry1QPTXcB-llY9vzIoRYIGdzUQqM3ltO';
  static const String finishing = '1N8WBaQdNtoZ6pNWFzxsM9sy_f3e7sN5H';
  static const String packing = '12sSZ3s9e5TGHMPhucRb_08eYENBjoUWN';
  static const String planner = '1qRMGqJO_efk9EZyLNnC9lLWS8I_5vEdi';
  static const String dailyProduction = '1Ur0IptBvACPE-6YHVut9YvECjwTr48Nx';
}

/// Represents a pending sync entry
class PendingSyncEntry {
  final String id;
  final String module; // 'cutting', 'production', 'lay'
  final Map<String, dynamic> data;
  final DateTime createdAt;
  bool synced;

  PendingSyncEntry({
    required this.id,
    required this.module,
    required this.data,
    required this.createdAt,
    this.synced = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'module': module,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'synced': synced,
  };

  factory PendingSyncEntry.fromJson(Map<String, dynamic> json) =>
      PendingSyncEntry(
        id: json['id'] as String,
        module: json['module'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        synced: json['synced'] as bool? ?? false,
      );
}

enum SyncStatus { idle, syncing, success, failed, noNetwork }

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _queueKey = 'sync_queue_v1';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncStatusKey = 'sync_status_message';

  SyncStatus _status = SyncStatus.idle;
  String _statusMessage = '';
  DateTime? _lastSyncTime;
  int _pendingCount = 0;

  SyncStatus get status => _status;
  String get statusMessage => _statusMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get pendingCount => _pendingCount;

  /// Initialize service — load persisted state
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(_lastSyncKey);
    if (lastSyncStr != null) {
      _lastSyncTime = DateTime.tryParse(lastSyncStr);
    }
    await _refreshPendingCount();
    notifyListeners();
  }

  /// Queue a new register entry for daily sync
  Future<void> queueEntry({
    required String module,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await _loadQueue(prefs);

    final entry = PendingSyncEntry(
      id: '${module}_${ISTUtils.now().millisecondsSinceEpoch}',
      module: module,
      data: {...data, '_queuedAt': ISTUtils.now().toIso8601String()},
      createdAt: ISTUtils.now(),
    );

    queue.add(entry);
    await _saveQueue(prefs, queue);
    _pendingCount = queue.where((e) => !e.synced).length;
    notifyListeners();
  }

  /// Trigger a manual sync — also called by the daily background task
  Future<bool> syncNow() async {
    if (_status == SyncStatus.syncing) return false;

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none) ||
        connectivity.isEmpty) {
      _setStatus(SyncStatus.noNetwork, 'No network — sync will retry');
      return false;
    }

    _setStatus(SyncStatus.syncing, 'Syncing entries to Google Sheets…');

    final prefs = await SharedPreferences.getInstance();
    final queue = await _loadQueue(prefs);
    final pending = queue.where((e) => !e.synced).toList();

    if (pending.isEmpty) {
      _lastSyncTime = ISTUtils.now();
      await prefs.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());
      _setStatus(SyncStatus.success, 'All entries are up to date');
      return true;
    }

    int successCount = 0;
    int failCount = 0;

    // Group by module for batch appending
    final grouped = <String, List<PendingSyncEntry>>{};
    for (final entry in pending) {
      grouped.putIfAbsent(entry.module, () => []).add(entry);
    }

    for (final module in grouped.keys) {
      final entries = grouped[module]!;
      final spreadsheetId = _getSpreadsheetId(module);
      if (spreadsheetId == null) continue;

      final sheetName = _getSheetName(module);
      final rows = entries.map((e) => _entryToRow(module, e.data)).toList();

      final ok = await _appendToSheet(
        spreadsheetId: spreadsheetId,
        sheetName: sheetName,
        rows: rows,
      );

      if (ok) {
        for (final e in entries) {
          e.synced = true;
        }
        successCount += entries.length;
      } else {
        failCount += entries.length;
      }
    }

    await _saveQueue(prefs, queue);
    _pendingCount = queue.where((e) => !e.synced).length;
    _lastSyncTime = ISTUtils.now();
    await prefs.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());

    if (failCount == 0) {
      _setStatus(
        SyncStatus.success,
        'Synced $successCount ${successCount == 1 ? 'entry' : 'entries'} successfully',
      );
      return true;
    } else if (successCount > 0) {
      _setStatus(
        SyncStatus.failed,
        'Synced $successCount, failed $failCount — will retry',
      );
      return false;
    } else {
      _setStatus(SyncStatus.failed, 'Sync failed — will retry tomorrow');
      return false;
    }
  }

  /// Check if a daily sync is due (once per day)
  Future<bool> isDailySyncDue() async {
    if (_lastSyncTime == null) return true;
    final now = ISTUtils.now();
    final lastSync = _lastSyncTime!;
    // Due if last sync was on a different calendar day (IST)
    return now.year != lastSync.year ||
        now.month != lastSync.month ||
        now.day != lastSync.day;
  }

  /// Run daily sync if due
  Future<void> runDailySyncIfDue() async {
    if (await isDailySyncDue()) {
      await syncNow();
    }
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  void _setStatus(SyncStatus status, String message) {
    _status = status;
    _statusMessage = message;
    notifyListeners();
  }

  Future<void> _refreshPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await _loadQueue(prefs);
    _pendingCount = queue.where((e) => !e.synced).length;
  }

  Future<List<PendingSyncEntry>> _loadQueue(SharedPreferences prefs) async {
    final raw = prefs.getString(_queueKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PendingSyncEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveQueue(
    SharedPreferences prefs,
    List<PendingSyncEntry> queue,
  ) async {
    // Keep only last 500 entries (synced or not) to avoid unbounded growth
    final trimmed = queue.length > 500
        ? queue.sublist(queue.length - 500)
        : queue;
    await prefs.setString(
      _queueKey,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  String? _getSpreadsheetId(String module) {
    switch (module) {
      case 'cutting':
        return RegisterSheetIds.cutting;
      case 'production':
        return RegisterSheetIds.dailyProduction;
      case 'lay':
        return RegisterSheetIds.lay;
      default:
        return null;
    }
  }

  String _getSheetName(String module) {
    switch (module) {
      case 'cutting':
        return 'Cutting Register';
      case 'production':
        return 'Daily Production';
      case 'lay':
        return 'Lay Register';
      default:
        return 'Sheet1';
    }
  }

  /// Convert a queued entry map to a flat row for Google Sheets
  List<dynamic> _entryToRow(String module, Map<String, dynamic> data) {
    final date = data['_queuedAt'] ?? ISTUtils.now().toIso8601String();
    switch (module) {
      case 'cutting':
        return [
          date,
          data['styleNo'] ?? '',
          data['color'] ?? '',
          data['designNo'] ?? '',
          data['avgConsumption'] ?? '',
          data['S'] ?? 0,
          data['M'] ?? 0,
          data['L'] ?? 0,
          data['XL'] ?? 0,
          data['2XL'] ?? 0,
          data['3XL'] ?? 0,
          data['4XL'] ?? 0,
          data['5XL'] ?? 0,
          data['6XL'] ?? 0,
          data['total'] ?? 0,
        ];
      case 'production':
        return [
          date,
          data['styleNo'] ?? '',
          data['color'] ?? '',
          data['lineNo'] ?? '',
          data['operation'] ?? '',
          data['operatorName'] ?? '',
          data['targetQty'] ?? 0,
          data['achievedQty'] ?? 0,
          data['efficiency'] ?? 0.0,
          data['remarks'] ?? '',
        ];
      case 'lay':
        return [
          date,
          data['styleNo'] ?? '',
          data['color'] ?? '',
          data['fabricRef'] ?? '',
          data['noOfLays'] ?? 0,
          data['layLength'] ?? '',
          data['totalPieces'] ?? 0,
          data['remarks'] ?? '',
        ];
      default:
        return [date, ...data.values];
    }
  }

  /// Append rows to a Google Sheet via REST API
  Future<bool> _appendToSheet({
    required String spreadsheetId,
    required String sheetName,
    required List<List<dynamic>> rows,
  }) async {
    const accessToken = String.fromEnvironment('GOOGLE_SHEETS_ACCESS_TOKEN');
    if (accessToken.isEmpty) {
      // No OAuth token available at runtime — log and skip
      debugPrint('[SyncService] No GOOGLE_SHEETS_ACCESS_TOKEN configured');
      return false;
    }

    try {
      final dio = Dio();
      final encodedSheet = Uri.encodeComponent(sheetName);
      final url =
          'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$encodedSheet!A1:append';

      final response = await dio.post(
        url,
        queryParameters: {
          'valueInputOption': 'USER_ENTERED',
          'insertDataOption': 'INSERT_ROWS',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
        data: {'values': rows},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[SyncService] Append failed: $e');
      return false;
    }
  }
}
