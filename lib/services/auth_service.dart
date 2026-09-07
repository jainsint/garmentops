import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { admin, staff }

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;
  AuthService._internal();

  UserRole _role = UserRole.staff;
  bool _isLoggedIn = false;

  UserRole get role => _role;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _role == UserRole.admin;

  static const String _adminId = 'admin';
  static const String _adminPassword = 'dhruv';
  static const String _prefKeyRole = 'user_role';
  static const String _prefKeyLoggedIn = 'is_logged_in';

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString(_prefKeyRole) ?? 'staff';
    _role = roleStr == 'admin' ? UserRole.admin : UserRole.staff;
    // Always treat the user as logged in on launch (default: staff).
    // The login screen is only shown when the user explicitly signs out
    // and the persisted flag is cleared.
    _isLoggedIn = prefs.getBool(_prefKeyLoggedIn) ?? true;
    if (!prefs.containsKey(_prefKeyLoggedIn)) {
      // First launch — persist the default staff session silently.
      _isLoggedIn = true;
      await _persist();
    }
    notifyListeners();
  }

  /// Returns null on success, error message on failure.
  Future<String?> loginAsAdmin(String id, String password) async {
    if (id.trim() == _adminId && password == _adminPassword) {
      _role = UserRole.admin;
      _isLoggedIn = true;
      await _persist();
      notifyListeners();
      return null;
    }
    return 'Invalid admin credentials';
  }

  Future<void> loginAsStaff() async {
    _role = UserRole.staff;
    _isLoggedIn = true;
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _role = UserRole.staff;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyLoggedIn);
    await prefs.remove(_prefKeyRole);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyLoggedIn, _isLoggedIn);
    await prefs.setString(
      _prefKeyRole,
      _role == UserRole.admin ? 'admin' : 'staff',
    );
  }
}
