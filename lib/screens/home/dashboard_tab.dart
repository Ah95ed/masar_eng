import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/error_state.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    if (dashboard.isLoading && dashboard.stats.isEmpty) {
      return const LoadingState(message: 'جاري تحميل لوحة المهندس...');
    }

    if (dashboard.errorMessage != null && dashboard.stats.isEmpty) {
      return ErrorState(
        message: dashboard.errorMessage!,
        onRetry: () => context.read<DashboardProvider>().fetchDashboard(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardProvider>().fetchDashboard(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              StatCard(
                title: 'مهام مفتوحة',
                value: dashboard.openTasks,
                icon: Icons.pending_actions,
                color: Colors.orange,
              ),
              StatCard(
                title: 'مهام منتهية',
                value: dashboard.completedTasks,
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
              StatCard(
                title: 'تقارير منتظرة',
                value: dashboard.pendingReports,
                icon: Icons.hourglass_top,
                color: Colors.blue,
              ),
              StatCard(
                title: 'تقارير معتمدة',
                value: dashboard.approvedReports,
                icon: Icons.verified_outlined,
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
