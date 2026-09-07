import 'package:flutter/foundation.dart';
import '../core/ist_utils.dart';

/// Central state notifier for cross-screen data sync.
/// Screens listen to this to refresh when register entries are added.
class AppStateService extends ChangeNotifier {
  static final AppStateService _instance = AppStateService._internal();
  static AppStateService get instance => _instance;
  AppStateService._internal();

  // Tracks the last time any register entry was written (in IST)
  DateTime _lastRegisterWrite = ISTUtils.now();
  DateTime get lastRegisterWrite => _lastRegisterWrite;

  // Recent activity entries (live, from Supabase)
  List<Map<String, dynamic>> _recentActivity = [];
  List<Map<String, dynamic>> get recentActivity =>
      List.unmodifiable(_recentActivity);

  bool _activityCleared = false;
  bool get activityCleared => _activityCleared;

  /// Called after any register entry is successfully saved to Supabase.
  void notifyRegisterWrite({
    required String register,
    required String styleNo,
    required String actor,
    int? quantity,
  }) {
    _lastRegisterWrite = ISTUtils.now();
    if (!_activityCleared) {
      _recentActivity.insert(0, {
        'register': register,
        'styleNo': styleNo,
        'actor': actor,
        'quantity': quantity,
        // Store IST timestamp so activity feed displays correctly
        'timestamp': ISTUtils.now(),
      });
      // Keep only last 50
      if (_recentActivity.length > 50) {
        _recentActivity = _recentActivity.sublist(0, 50);
      }
    }
    notifyListeners();
  }

  void clearActivity() {
    _activityCleared = true;
    _recentActivity = [];
    notifyListeners();
  }

  void restoreActivity() {
    _activityCleared = false;
    notifyListeners();
  }
}
