import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../tasks/tasks_screen.dart';
import '../reports/reports_screen.dart';
import '../reports/report_form_screen.dart';
import '../notifications/notifications_screen.dart';
import '../auth/login_screen.dart';
import 'dashboard_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.api});
  final EngineerApi api;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DashboardTab(api: widget.api),
      TasksScreen(api: widget.api),
      ReportsScreen(api: widget.api),
      NotificationsScreen(api: widget.api),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text([
          'لوحة المهندس',
          'مهامي',
          'تقاريري',
          'الإشعارات',
        ][_index]),
        actions: [
          if (_index == 2)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'تقرير جديد',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportFormScreen(api: widget.api),
                  ),
                );
                setState(() {});
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              final nav = Navigator.of(context);
              final auth = context.read<AuthProvider>();
              final tasks = context.read<TasksProvider>();
              final reports = context.read<ReportsProvider>();
              final notifs = context.read<NotificationsProvider>();
              final dash = context.read<DashboardProvider>();

              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('خروج'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await auth.logout();
                tasks.reset();
                reports.reset();
                notifs.reset();
                dash.reset();

                if (!mounted) return;
                nav.pushReplacement(
                  MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
                );
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'مهامي',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'تقاريري',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'الإشعارات',
          ),
        ],
      ),
      floatingActionButton: (_index == 1 || _index == 2)
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportFormScreen(api: widget.api),
                  ),
                );
                setState(() {});
              },
              icon: const Icon(Icons.add),
              label: const Text('تقرير يومي'),
            )
          : null,
    );
  }
}
