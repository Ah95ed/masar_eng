import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/engineer_api.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/error_state.dart';
import '../../core/responsive.dart';

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

  Color _statusColor(String s) {
    switch (s) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'submitted': return Colors.blue;
      case 'draft': return Colors.orange;
      default: return Colors.grey;
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
    final isWide = Responsive.isWide(context);

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: RefreshIndicator(
            onRefresh: () => reportsProv.fetchReportDetail(widget.reportId),
            child: ListView(
              padding: EdgeInsets.all(isWide ? 24 : 16),
              children: [
                _buildHeaderCard(r, isWide),
                const SizedBox(height: 16),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _section('الأعمال المنجزة', '${r['work_done'] ?? '-'}', Icons.construction),
                            _section('المشاكل والمعوقات', '${r['issues'] ?? '-'}', Icons.warning_amber),
                            _section('المواد المستخدمة', '${r['materials_used'] ?? '-'}', Icons.inventory_2_outlined),
                            _section('ملاحظات السلامة', '${r['safety_notes'] ?? '-'}', Icons.health_and_safety_outlined),
                            if (r['admin_notes'] != null && (r['admin_notes'] as String).isNotEmpty)
                              _section('ملاحظات الإدارة', '${r['admin_notes']}', Icons.admin_panel_settings_outlined),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildExpensesCard(expenses),
                            const SizedBox(height: 16),
                            _buildReceiptsCard(receipts, reportsProv),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _section('الأعمال المنجزة', '${r['work_done'] ?? '-'}', Icons.construction),
                  _section('المشاكل والمعوقات', '${r['issues'] ?? '-'}', Icons.warning_amber),
                  _section('المواد المستخدمة', '${r['materials_used'] ?? '-'}', Icons.inventory_2_outlined),
                  _section('ملاحظات السلامة', '${r['safety_notes'] ?? '-'}', Icons.health_and_safety_outlined),
                  if (r['admin_notes'] != null && (r['admin_notes'] as String).isNotEmpty)
                    _section('ملاحظات الإدارة', '${r['admin_notes']}', Icons.admin_panel_settings_outlined),
                  const SizedBox(height: 16),
                  _buildExpensesCard(expenses),
                  const SizedBox(height: 16),
                  _buildReceiptsCard(receipts, reportsProv),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> r, bool isWide) {
    final status = '${r['status']}';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r['site_name'] ?? 'تقرير موقع'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        'التاريخ: ${r['report_date']}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _statusColor(status).withAlpha(120)),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _metricBadge(Icons.cloud_outlined, 'الطقس', '${r['weather'] ?? '-'}'),
                _metricBadge(Icons.thermostat, 'الحرارة', '${r['temperature'] ?? '-'}°م'),
                _metricBadge(Icons.people_outline, 'العمال', '${r['workers_count']}'),
                _metricBadge(Icons.precision_manufacturing_outlined, 'الآليات', '${r['machinery_count']}'),
                _metricBadge(Icons.trending_up, 'نسبة الإنجاز', '${r['progress_percent']}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBadge(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _section(String title, String content, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(height: 1.5, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesCard(List expenses) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 20, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'المصروفات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '${expenses.length} بند',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 20),
            if (expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('لا توجد مصروفات مسجلة', style: TextStyle(color: Colors.grey)),
              )
            else
              ...expenses.map((e) {
                final m = Map<String, dynamic>.from(e as Map);
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${m['item_name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              '${m['category']} • ${m['quantity']} × ${m['unit_price']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${m['total']} د.ع',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptsCard(List receipts, ReportsProvider reportsProv) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 20, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'المرفقات والإيصالات',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: reportsProv.isUploadingReceipt ? null : _pickAndUpload,
                  icon: const Icon(Icons.add_a_photo, size: 16),
                  label: const Text('إضافة', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            if (receipts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('لا توجد مرفقات بعد', style: TextStyle(color: Colors.grey)),
              )
            else
              ...receipts.map((e) {
                final m = Map<String, dynamic>.from(e as Map);
                final sizeInKb = (m['file_size'] is num) ? ((m['file_size'] as num) / 1024).round() : 0;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image, color: Colors.teal, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m['original_name'] ?? 'مرفق'}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$sizeInKb KB • ${m['file_type'] ?? ''}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

