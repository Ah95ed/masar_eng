import 'package:flutter/foundation.dart';
import '../services/engineer_api.dart';
import '../core/api_exception.dart';

class ReportsProvider with ChangeNotifier {
  ReportsProvider({required this.api});

  final EngineerApi api;

  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _sites = [];
  Map<String, dynamic>? _selectedReport;

  bool _isLoadingReports = false;
  bool _isLoadingDetail = false;
  bool _isLoadingSites = false;
  bool _isSaving = false;
  bool _isUploadingReceipt = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get reports => _reports;
  List<Map<String, dynamic>> get sites => _sites;
  Map<String, dynamic>? get selectedReport => _selectedReport;

  bool get isLoadingReports => _isLoadingReports;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get isLoadingSites => _isLoadingSites;
  bool get isSaving => _isSaving;
  bool get isUploadingReceipt => _isUploadingReceipt;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReports({String? status, int? siteId}) async {
    _isLoadingReports = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final query = <String, String>{};
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (siteId != null) query['site_id'] = '$siteId';

      final data = await api.get('reports', query);
      _reports = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _isLoadingReports = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoadingReports = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر تحميل التقارير';
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  Future<void> fetchReportDetail(int id) async {
    _isLoadingDetail = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await api.get('reports', {'id': '$id'});
      _selectedReport = Map<String, dynamic>.from(data as Map);
      _isLoadingDetail = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoadingDetail = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر تحميل تفاصيل التقرير';
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<void> fetchSites() async {
    _isLoadingSites = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await api.get('sites');
      _sites = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _isLoadingSites = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoadingSites = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'تعذر تحميل قائمة المواقع';
      _isLoadingSites = false;
      notifyListeners();
    }
  }

  Future<bool> createReport(Map<String, dynamic> reportData) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await api.post('reports', reportData);
      _isSaving = false;
      notifyListeners();
      // تحديث قائمة التقارير تلقائياً بعد الإرسال
      await fetchReports();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'تعذر إرسال التقرير';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadReceipt({
    required int reportId,
    required String filePath,
    required String fileName,
  }) async {
    _isUploadingReceipt = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await api.uploadReceipt(
        reportId: reportId,
        filePath: filePath,
        fileName: fileName,
      );
      _isUploadingReceipt = false;
      notifyListeners();
      // إعادة تحميل تفاصيل التقرير لإظهار المرفق الجديد مباشرة
      await fetchReportDetail(reportId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isUploadingReceipt = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'تعذر رفع المرفق';
      _isUploadingReceipt = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _reports = [];
    _sites = [];
    _selectedReport = null;
    _isLoadingReports = false;
    _isLoadingDetail = false;
    _isLoadingSites = false;
    _isSaving = false;
    _isUploadingReceipt = false;
    _errorMessage = null;
    notifyListeners();
  }
}
