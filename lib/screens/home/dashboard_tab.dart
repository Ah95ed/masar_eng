import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../core/responsive.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/error_state.dart';
import '../reports/report_form_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key, required this.api});
  final EngineerApi api;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboard();
      context.read<TasksProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final tasksProv = context.watch<TasksProvider>();
    final isDesktop = Responsive.isDesktop(context);
    final columns = Responsive.gridColumns(context, mobile: 2, tablet: 4, desktop: 4);

    if (dashboard.isLoading && dashboard.stats.isEmpty) {
      return const LoadingState(message: 'جاري تحميل لوحة المهندس...');
    }

    if (dashboard.errorMessage != null && dashboard.stats.isEmpty) {
      return ErrorState(
        message: dashboard.errorMessage!,
        onRetry: () => context.read<DashboardProvider>().fetchDashboard(),
      );
    }

    final urgentTasks = tasksProv.tasks.where((t) => t['priority'] == 'urgent' || t['priority'] == 'high').take(4).toList();

    return RefreshIndicator(
      onRefresh: () => Future.wait([
        context.read<DashboardProvider>().fetchDashboard(),
        context.read<TasksProvider>().fetchTasks(),
      ]),
      child: ListView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        children: [
          // عنوان ترحيبي
          Text(
            'نظرة عامة على مشاريعك الميدانية',
            style: TextStyle(
              fontSize: isDesktop ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF102B3F),
            ),
          ),
          const SizedBox(height: 16),

          // شبكة الإحصائيات المتكيفة مع حجم الشاشة
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: isDesktop ? 1.6 : 1.35,
            children: [
              StatCard(
                title: 'مهام مفتوحة',
                value: dashboard.openTasks,
                icon: Icons.pending_actions_rounded,
                color: Colors.orange.shade700,
              ),
              StatCard(
                title: 'مهام منتهية',
                value: dashboard.completedTasks,
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF13805D),
              ),
              StatCard(
                title: 'تقارير منتظرة',
                value: dashboard.pendingReports,
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFF078DA5),
              ),
              StatCard(
                title: 'تقارير معتمدة',
                value: dashboard.approvedReports,
                icon: Icons.verified_outlined,
                color: Colors.teal.shade700,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // إجراءات سريعة للمهندس
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13805D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.post_add_rounded, color: Color(0xFF13805D), size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تسجيل تقرير العمل اليومي',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'أرسل نسب الإنجاز والمواد والمصروفات الميدانية لاعتمادها من الإدارة',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportFormScreen(api: widget.api),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('تقرير جديد'),
                  ),
                ],
              ),
            ),
          ),

          if (urgentTasks.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'المهام ذات الأولوية العالية',
              style: TextStyle(
                fontSize: isDesktop ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF102B3F),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 2 : 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 95,
              ),
              itemCount: urgentTasks.length,
              itemBuilder: (context, i) {
                final t = urgentTasks[i];
                final progress = ((t['progress'] ?? 0) as num).toInt();
                final isUrgent = t['priority'] == 'urgent';

                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: isUrgent ? Colors.red : Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${t['title']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${t['site_name']}',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$progress%',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 60,
                              child: LinearProgressIndicator(
                                value: (progress / 100).clamp(0.0, 1.0),
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
