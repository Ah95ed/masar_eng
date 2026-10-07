import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/engineer_api.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/error_state.dart';

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({
    super.key,
    required this.api,
    required this.reportId,
  });
  final EngineerApi api;
  final int reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchReportDetail(widget.reportId);
    });
  }

  Future<void> _pickAndUpload() async {
    final reportsProv = context.read<ReportsProvider>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final success = await reportsProv.uploadReceipt(
      reportId: widget.reportId,
      filePath: picked.path,
      fileName: picked.name,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم رفع المرفق بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${reportsProv.errorMessage ?? "تعذر رفع المرفق"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'approved': return 'معتمد';
      case 'rejected': return 'مرفوض';
      case 'submitted': return 'مرسل';
      case 'draft': return 'مسودة';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProv = context.watch<ReportsProvider>();
    final r = reportsProv.selectedReport;

    if (reportsProv.isLoadingDetail && r == null) {
      return const Scaffold(
        body: LoadingState(message: 'جاري تحميل تفاصيل التقرير...'),
      );
    }

    if (reportsProv.errorMessage != null && r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: reportsProv.errorMessage!,
          onRetry: () => reportsProv.fetchReportDetail(widget.reportId),
        ),
      );
    }

    if (r == null) {
      return const Scaffold(
        body: Center(child: Text('التقرير غير موجود')),
      );
    }

    final expenses = (r['expenses'] as List?) ?? [];
    final receipts = (r['receipts'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${r['site_name'] ?? 'تفاصيل التقرير'}'),
        actions: [
          IconButton(
            icon: reportsProv.isUploadingReceipt
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.attach_file),
            tooltip: 'رفع مرفق',
            onPressed: reportsProv.isUploadingReceipt ? null : _pickAndUpload,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => reportsProv.fetchReportDetail(widget.reportId),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text('${r['report_date']}'),
                        const Spacer(),
                        Chip(label: Text(_statusLabel('${r['status']}'))),
                      ],
                    ),
                    const Divider(),
                    _row('الطقس', '${r['weather'] ?? '-'}'),
                    _row('درجة الحرارة', '${r['temperature'] ?? '-'}'),
                    _row('العمال', '${r['workers_count']}'),
                    _row('الآليات', '${r['machinery_count']}'),
                    _row('الإنجاز', '${r['progress_percent']}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _section('الأعمال المنجزة', '${r['work_done'] ?? '-'}'),
            _section('المشاكل', '${r['issues'] ?? '-'}'),
            _section('المواد', '${r['materials_used'] ?? '-'}'),
            _section('السلامة', '${r['safety_notes'] ?? '-'}'),
            if (r['admin_notes'] != null && (r['admin_notes'] as String).isNotEmpty)
              _section('ملاحظات الإدارة', '${r['admin_notes']}'),
            const SizedBox(height: 16),
            const Text('المصروفات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (expenses.isEmpty)
              const Text('لا توجد مصروفات مسجلة', style: TextStyle(color: Colors.grey))
            else
              ...expenses.map((e) {
                final m = Map<String, dynamic>.from(e as Map);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text('${m['item_name']}'),
                    subtitle: Text(
                        '${m['category']} • ${m['quantity']} × ${m['unit_price']}'),
                    trailing: Text('${m['total']} د.ع', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            const SizedBox(height: 16),
            const Text('المرفقات والإيصالات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            if (receipts.isEmpty)
              const Text('لا توجد مرفقات', style: TextStyle(color: Colors.grey))
            else
              ...receipts.map((e) {
                final m = Map<String, dynamic>.from(e as Map);
                final sizeInKb = (m['file_size'] is num) ? ((m['file_size'] as num) / 1024).round() : 0;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.image, color: Colors.teal),
                    title: Text('${m['original_name'] ?? 'مرفق'}'),
                    subtitle: Text(
                        '$sizeInKb KB • ${m['file_type'] ?? ''}'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(content),
          ],
        ),
      ),
    );
  }
}
