import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/engineer_api.dart';
import '../core/api_exception.dart';

class NotificationsProvider with ChangeNotifier {
  NotificationsProvider({required this.api});

  final EngineerApi api;

  List<NotificationModel> _items = [];
  bool _isLoading = false;
  String? _error;
  int _lastUnreadCount = 0;

  List<NotificationModel> get items => _items;
  List<NotificationModel> get notifications => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _error;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> fetchNotifications({
    bool silent = false,
    void Function(NotificationModel latestItem)? onNewNotificationReceived,
  }) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final res = await api.get('notifications');
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['notifications'] ?? res['data'] ?? [];
      }

      final fetched = rawList
          .whereType<Map>()
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final currentUnread = fetched.where((n) => !n.isRead).length;

      // تحقق مما إذا كان هناك إشعار جديد وصل للتو
      if (currentUnread > _lastUnreadCount && fetched.isNotEmpty) {
        final latest = fetched.first;
        if (!latest.isRead && onNewNotificationReceived != null) {
          onNewNotificationReceived(latest);
        }
      }
      _lastUnreadCount = currentUnread;

      _items = fetched;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      if (!silent) {
        _error = e.message;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (!silent) {
        _error = 'تعذر جلب الإشعارات';
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final idx = _items.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(isRead: true);
      _lastUnreadCount = unreadCount;
      notifyListeners();
    }

    try {
      await api.post('notification-read', {'notification_id': notificationId});
    } catch (_) {
      await fetchNotifications(silent: true);
    }
  }

  Future<void> markAllAsRead() async {
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    _lastUnreadCount = 0;
    notifyListeners();

    try {
      await api.post('notification-read-all', {});
    } catch (_) {
      await fetchNotifications(silent: true);
    }
  }

  void reset() {
    _items = [];
    _isLoading = false;
    _error = null;
    _lastUnreadCount = 0;
    notifyListeners();
  }
}
