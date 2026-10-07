import 'package:flutter/foundation.dart';
import '../services/engineer_api.dart';
import '../core/api_exception.dart';

class TasksProvider with ChangeNotifier {
  TasksProvider({required this.api});

  final EngineerApi api;

  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;
  String _filterStatus = '';

  List<Map<String, dynamic>> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  String get filterStatus => _filterStatus;

  List<Map<String, dynamic>> get filteredTasks {
    if (_filterStatus.isEmpty) return _tasks;
    return _tasks.where((t) => t['status'] == _filterStatus).toList();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  Future<void> fetchTasks({int? siteId, String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final query = <String, String>{};
      if (siteId != null) query['site_id'] = '$siteId';
      if (status != null && status.isNotEmpty) query['status'] = status;

      final data = await api.get('tasks', query);
      _tasks = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر تحميل قائمة المهام';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTaskProgress({
    required int taskId,
    required int progress,
    required String status,
    String? note,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final actualProgress = (status == 'done') ? 100 : progress;

      final res = await api.post('task-update', {
        'task_id': taskId,
        'progress': actualProgress,
        'status': status,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });

      // تحديث فوري محلي في القائمة لإظهار التغيير فوراً دون انتظار إعادة الجلب
      final index = _tasks.indexWhere((t) => t['id'] == taskId);
      if (index != -1) {
        final updated = Map<String, dynamic>.from(_tasks[index]);
        updated['progress'] = res['progress'] ?? actualProgress;
        updated['status'] = res['status'] ?? status;
        _tasks[index] = updated;
      }

      _isUpdating = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isUpdating = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'فشل تحديث المهمة';
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _tasks = [];
    _isLoading = false;
    _isUpdating = false;
    _errorMessage = null;
    _filterStatus = '';
    notifyListeners();
  }
}
