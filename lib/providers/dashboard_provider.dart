import 'package:flutter/foundation.dart';
import '../services/engineer_api.dart';
import '../core/api_exception.dart';

class DashboardProvider with ChangeNotifier {
  DashboardProvider({required this.api});

  final EngineerApi api;

  Map<String, dynamic> _stats = {
    'open_tasks': 0,
    'completed_tasks': 0,
    'pending_reports': 0,
    'approved_reports': 0,
  };
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get openTasks => _stats['open_tasks'] ?? 0;
  int get completedTasks => _stats['completed_tasks'] ?? 0;
  int get pendingReports => _stats['pending_reports'] ?? 0;
  int get approvedReports => _stats['approved_reports'] ?? 0;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await api.get('dashboard');
      _stats = Map<String, dynamic>.from(data as Map);
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر تحميل إحصائيات لوحة المهندس';
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _stats = {
      'open_tasks': 0,
      'completed_tasks': 0,
      'pending_reports': 0,
      'approved_reports': 0,
    };
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
