import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/reports_provider.dart';
import '../../core/responsive.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/empty_state.dart';
import 'report_detail_screen.dart';
import 'report_form_screen.dart';

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
      case 'approved': return const Color(0xFF13805D);
      case 'rejected': return const Color(0xFFBD3F42);
      case 'submitted': return const Color(0xFFB76B08);
      case 'draft': return Colors.grey;
      default: return const Color(0xFF078DA5);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'approved': return 'معتمد';
      case 'rejected': return 'مرفوض';
      case 'submitted': return 'مرسل للمراجعة';
      case 'draft': return 'مسودة';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProv = context.watch<ReportsProvider>();
    final items = reportsProv.reports;
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);
    final gridCols = Responsive.gridColumns(context, mobile: 1, tablet: 2, desktop: 3);

    if (reportsProv.isLoadingReports && items.isEmpty) {
      return const LoadingState(message: 'جاري تحميل التقارير اليومية...');
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
          children: [
            const SizedBox(height: 100),
            const EmptyState(
              message: 'لا توجد تقارير يومية حتى الآن',
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportFormScreen(api: widget.api),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إنشاء أول تقرير يومي'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ReportsProvider>().fetchReports(),
      child: isMobile
          // =================== عرض الهاتف (ListView) ===================
          ? ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _buildMobileCard(items[i]),
            )
          // =================== عرض الويندوز والتابلت (GridView) ===================
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridCols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.5 : 1.35,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => _buildDesktopCard(items[i]),
            ),
    );
  }

  /// كارد التقرير للهاتف
  Widget _buildMobileCard(Map<String, dynamic> r) {
    final status = '${r['status']}';

    return Card(
      elevation: 0.8,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _statusColor(status).withValues(alpha: 0.12),
          child: Icon(Icons.description_rounded, color: _statusColor(status)),
        ),
        title: Text(
          '${r['site_name']}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text('${r['report_date']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const Spacer(),
                Text('إنجاز: ${r['progress_percent']}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            _buildStatusBadge(status),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReportDetailScreen(api: widget.api, reportId: r['id'] as int),
            ),
          );
        },
      ),
    );
  }

  /// كارد التقرير المتطور للويندوز والتابلت
  Widget _buildDesktopCard(Map<String, dynamic> r) {
    final status = '${r['status']}';

    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReportDetailScreen(api: widget.api, reportId: r['id'] as int),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الرأس: اسم الموقع والتاريخ
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _statusColor(status).withValues(alpha: 0.12),
                    child: Icon(Icons.description_rounded, color: _statusColor(status), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r['site_name']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102B3F)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.event_note_rounded, size: 14, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text('${r['report_date']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),

              // ملخص الأعمال والبيانات
              if (r['work_done'] != null && (r['work_done'] as String).isNotEmpty)
                Text(
                  '${r['work_done']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4),
                ),

              // معلومات العمال والآليات ونسبة الإنجاز
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricItem('عمال', '${r['workers_count'] ?? 0}'),
                    const SizedBox(width: 8),
                    _metricItem('آليات', '${r['machinery_count'] ?? 0}'),
                    const SizedBox(width: 8),
                    _metricItem('الإنجاز', '${r['progress_percent'] ?? 0}%'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF102B3F))),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
