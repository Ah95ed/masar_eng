import 'expense.dart';
import 'receipt.dart';

class DailyReport {
  final int id;
  final int siteId;
  final String siteName;
  final int engineerId;
  final String? engineerName;
  final String reportDate;
  final String? weather;
  final double? temperature;
  final int workersCount;
  final int machineryCount;
  final String? workDone;
  final String? issues;
  final String? materialsUsed;
  final String? safetyNotes;
  final int progressPercent;
  final String status;
  final String? adminNotes;
  final int? approvedBy;
  final String? approvedAt;
  final String? createdAt;
  final List<ExpenseItem> expenses;
  final List<ReceiptItem> receipts;

  const DailyReport({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.engineerId,
    this.engineerName,
    required this.reportDate,
    this.weather,
    this.temperature,
    this.workersCount = 0,
    this.machineryCount = 0,
    this.workDone,
    this.issues,
    this.materialsUsed,
    this.safetyNotes,
    this.progressPercent = 0,
    required this.status,
    this.adminNotes,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.expenses = const [],
    this.receipts = const [],
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    final expList = (json['expenses'] as List?)
            ?.map((e) => ExpenseItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];
    final recList = (json['receipts'] as List?)
            ?.map((e) => ReceiptItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    final tempVal = (json['temperature'] is num)
        ? (json['temperature'] as num).toDouble()
        : double.tryParse('${json['temperature']}');

    return DailyReport(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      siteId: json['site_id'] is int ? json['site_id'] : int.tryParse('${json['site_id']}') ?? 0,
      siteName: json['site_name']?.toString() ?? '',
      engineerId: json['engineer_id'] is int ? json['engineer_id'] : int.tryParse('${json['engineer_id']}') ?? 0,
      engineerName: json['engineer_name']?.toString(),
      reportDate: json['report_date']?.toString() ?? '',
      weather: json['weather']?.toString(),
      temperature: tempVal,
      workersCount: json['workers_count'] is int ? json['workers_count'] : int.tryParse('${json['workers_count']}') ?? 0,
      machineryCount: json['machinery_count'] is int ? json['machinery_count'] : int.tryParse('${json['machinery_count']}') ?? 0,
      workDone: json['work_done']?.toString(),
      issues: json['issues']?.toString(),
      materialsUsed: json['materials_used']?.toString(),
      safetyNotes: json['safety_notes']?.toString(),
      progressPercent: json['progress_percent'] is int ? json['progress_percent'] : int.tryParse('${json['progress_percent']}') ?? 0,
      status: json['status']?.toString() ?? 'draft',
      adminNotes: json['admin_notes']?.toString(),
      approvedBy: json['approved_by'] is int ? json['approved_by'] : int.tryParse('${json['approved_by']}'),
      approvedAt: json['approved_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      expenses: expList,
      receipts: recList,
    );
  }
}
