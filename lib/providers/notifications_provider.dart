import 'package:flutter/foundation.dart';
import '../services/engineer_api.dart';
import '../core/api_exception.dart';

class NotificationsProvider with ChangeNotifier {
  NotificationsProvider({required this.api});

  final EngineerApi api;

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount =>
      _notifications.where((n) => n['is_read'] != 1).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await api.get('notifications');
      _notifications = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر تحميل الإشعارات';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    // تحديث محلي فوري
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['is_read'] = 1;
      notifyListeners();
    }

    try {
      await api.post('notification-read', {'notification_id': id});
    } catch (_) {
      // في حال الخطأ نعيد الجلب
      await fetchNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n['is_read'] = 1;
    }
    notifyListeners();

    try {
      await api.post('notification-read-all', {});
    } catch (_) {
      await fetchNotifications();
    }
  }

  void reset() {
    _notifications = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
