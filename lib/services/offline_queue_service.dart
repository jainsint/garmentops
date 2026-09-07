import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './supabase_service.dart';

/// Represents a queued write operation for offline support.
class QueuedWrite {
  final String id;
  final String operation; // 'insert', 'update', 'delete'
  final String module;
  final Map<String, dynamic> data;
  final String? recordId; // for update/delete
  final DateTime queuedAt;

  QueuedWrite({
    required this.id,
    required this.operation,
    required this.module,
    required this.data,
    this.recordId,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'operation': operation,
    'module': module,
    'data': data,
    'recordId': recordId,
    'queuedAt': queuedAt.toIso8601String(),
  };

  factory QueuedWrite.fromJson(Map<String, dynamic> json) => QueuedWrite(
    id: json['id'] as String,
    operation: json['operation'] as String,
    module: json['module'] as String,
    data: Map<String, dynamic>.from(json['data'] as Map),
    recordId: json['recordId'] as String?,
    queuedAt: DateTime.parse(json['queuedAt'] as String),
  );
}

class OfflineQueueService extends ChangeNotifier {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  static OfflineQueueService get instance => _instance;
  OfflineQueueService._internal();

  static const String _queueKey = 'offline_write_queue_v2';

  List<QueuedWrite> _queue = [];
  bool _isOnline = true;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  List<QueuedWrite> get queue => List.unmodifiable(_queue);
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _queue.length;
  bool get hasPending => _queue.isNotEmpty;

  Future<void> initialize() async {
    await _loadQueue();
    await _checkConnectivity();
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none) && result.isNotEmpty;
    notifyListeners();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline;
    _isOnline =
        !results.contains(ConnectivityResult.none) && results.isNotEmpty;
    notifyListeners();
    // Auto-sync when coming back online
    if (wasOffline && _isOnline && _queue.isNotEmpty) {
      syncQueue();
    }
  }

  /// Enqueue a write for later sync (used when offline).
  Future<void> enqueue(QueuedWrite write) async {
    _queue.add(write);
    await _saveQueue();
    notifyListeners();
  }

  /// Attempt to sync all queued writes to Supabase.
  Future<SyncResult> syncQueue() async {
    if (_isSyncing || _queue.isEmpty) return SyncResult(synced: 0, failed: 0);
    if (!_isOnline) return SyncResult(synced: 0, failed: 0);

    _isSyncing = true;
    notifyListeners();

    int synced = 0;
    int failed = 0;
    final toRemove = <String>[];

    for (final write in List.from(_queue)) {
      try {
        await _executeWrite(write);
        toRemove.add(write.id);
        synced++;
      } catch (_) {
        failed++;
      }
    }

    _queue.removeWhere((w) => toRemove.contains(w.id));
    await _saveQueue();
    _isSyncing = false;
    notifyListeners();
    return SyncResult(synced: synced, failed: failed);
  }

  Future<void> _executeWrite(QueuedWrite write) async {
    final svc = SupabaseService.instance;
    switch (write.operation) {
      case 'insert':
        switch (write.module) {
          case 'cutting':
            await svc.insertCuttingEntry(write.data);
            break;
          case 'lay':
            await svc.insertLayEntry(write.data);
            break;
          case 'ironing':
            await svc.insertIroningEntry(write.data);
            break;
          case 'checking':
            await svc.insertCheckingEntry(write.data);
            break;
          case 'fabricStock':
            await svc.insertFabricStockEntry(write.data);
            break;
          case 'buttoning':
            await svc.insertButtoningEntry(write.data);
            break;
          case 'stitching':
            await svc.insertStitchingEntry(write.data);
            break;
          case 'washing':
            await svc.insertWashingEntryFromForm(write.data);
            break;
          case 'clientOrder':
            await svc.insertClientOrder(write.data);
            break;
        }
        break;
      case 'update':
        if (write.recordId != null) {
          await svc.updateEntry(write.module, write.recordId!, write.data);
        }
        break;
      case 'delete':
        if (write.recordId != null) {
          await svc.deleteEntry(write.module, write.recordId!);
        }
        break;
    }
  }

  Future<void> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_queueKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _queue = list
          .map((e) => QueuedWrite.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _queue = [];
    }
  }

  Future<void> _saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _queueKey,
      jsonEncode(_queue.map((w) => w.toJson()).toList()),
    );
  }
}

class SyncResult {
  final int synced;
  final int failed;
  SyncResult({required this.synced, required this.failed});
}
