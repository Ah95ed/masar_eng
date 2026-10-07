import 'package:flutter/foundation.dart';

import '../services/engineer_api.dart';
import '../services/session_manager.dart';
import '../models/user.dart';
import '../core/api_exception.dart';

/// موفر الحالة لإدارة جلسة ومصادقة المهندس باستخدام Provider
class AuthProvider with ChangeNotifier {
  AuthProvider({required this.api}) {
    _initFromSession();
  }

  final EngineerApi api;
  final SessionManager _session = SessionManager.instance;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _session.isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _initFromSession() {
    if (_session.user != null) {
      _currentUser = User.fromJson(_session.user!);
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userData = await api.login(username: username, password: password);
      _currentUser = User.fromJson(userData);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'حدث خطأ غير متوقع في الاتصال';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await api.logout();
    } finally {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> restoreSession() async {
    final ok = await api.restoreSession();
    if (ok && _session.user != null) {
      _currentUser = User.fromJson(_session.user!);
    } else {
      _currentUser = null;
    }
    notifyListeners();
    return ok;
  }
}
