import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/empty_state.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.api});
  final EngineerApi api;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportsProvider>().fetchReports();
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'submitted': return Colors.orange;
      case 'draft': return Colors.grey;
      default: return Colors.blue;
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
    final items = reportsProv.reports;

    if (reportsProv.isLoadingReports && items.isEmpty) {
      return const LoadingState(message: 'جاري تحميل التقارير...');
    }

    if (reportsProv.errorMessage != null && items.isEmpty) {
      return ErrorState(
        message: reportsProv.errorMessage!,
        onRetry: () => context.read<ReportsProvider>().fetchReports(),
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<ReportsProvider>().fetchReports(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            EmptyState(
              message: 'لا توجد تقارير يومية حتى الآن',
              icon: Icons.description_outlined,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ReportsProvider>().fetchReports(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final r = items[i];
          final status = '${r['status']}';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(status).withValues(alpha: 0.15),
                child: Icon(Icons.description,
                    color: _statusColor(status)),
              ),
              title: Text('${r['site_name']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('التاريخ: ${r['report_date']}'),
                  Text('إنجاز: ${r['progress_percent']}%'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _statusLabel(status),
                      style: TextStyle(
                          color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(
                      api: widget.api,
                      reportId: r['id'] as int,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
