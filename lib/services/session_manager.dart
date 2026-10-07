import 'package:flutter/foundation.dart';
import '../core/secure_storage.dart';

class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  String? _token;
  Map<String, dynamic>? _user;
  bool _restored = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isRestored => _restored;

  Future<void> restore() async {
    final saved = await SecureStorage.instance.readToken();
    _token = saved;
    _restored = true;
    if (kDebugMode) {
      debugPrint('🔑 Session restore: ${saved == null ? "no token" : "token found"}');
    }
  }

  Future<void> setSession(String token, Map<String, dynamic> user) async {
    _token = token;
    _user = user;
    await SecureStorage.instance.saveToken(token);
    if (kDebugMode) {
      debugPrint('🔑 Session saved: token=${token.substring(0, 20)}...');
    }
  }

  void updateUser(Map<String, dynamic> user) {
    _user = user;
  }

  Future<void> clear() async {
    _token = null;
    _user = null;
    await SecureStorage.instance.clearToken();
  }
}
