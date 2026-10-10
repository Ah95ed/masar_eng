import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/responsive.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_badge_button.dart';
import '../../widgets/auto_refresh_wrapper.dart';
import '../../widgets/in_app_notification_toast.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'لوحة المهندس',
    'مهامي الميدانية',
    'تقاريري اليومية',
    'التنبيهات والإشعارات',
  ];

  @override
  void initState() {
    super.initState();
    NotificationService.onNotificationTapped = (payload) {
      if (payload != null && payload.isNotEmpty) {
        NotificationService.instance.handleNotificationPayload(payload);
      } else {
        if (mounted) setState(() => _index = 3);
      }
    };
  }

  void _handleNotificationTap(NotificationModel item) {
    context.read<NotificationsProvider>().markAsRead(item.id);
    final link = item.link;
    if (link != null && link.isNotEmpty) {
      NotificationService.instance.handleNotificationPayload(link);
    } else {
      if (mounted) setState(() => _index = 3);
    }
  }

  Future<void> _refreshAll() async {
    final tasks = context.read<TasksProvider>();
    final reports = context.read<ReportsProvider>();
    final notifs = context.read<NotificationsProvider>();
    final dash = context.read<DashboardProvider>();

    await Future.wait([
      tasks.fetchTasks(),
      reports.fetchReports(),
      notifs.fetchNotifications(),
      dash.fetchDashboard(),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث البيانات'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _logout() async {
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

      nav.pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isWide(context);
    final unreadCount = context.watch<NotificationsProvider>().unreadCount;

    final tabs = [
      DashboardTab(api: widget.api),
      TasksScreen(api: widget.api),
      ReportsScreen(api: widget.api),
      NotificationsScreen(api: widget.api),
    ];

    return AutoRefreshWrapper(
      interval: const Duration(seconds: 15),
      onRefresh: () async {
        final notifs = context.read<NotificationsProvider>();
        final tasks = context.read<TasksProvider>();
        final reports = context.read<ReportsProvider>();
        final dash = context.read<DashboardProvider>();

        await notifs.fetchNotifications(
          silent: true,
          onNewNotificationReceived: (latest) {
            if (latest.type.contains('task')) {
              tasks.fetchTasks();
              dash.fetchDashboard();
            } else if (latest.type.contains('report')) {
              reports.fetchReports();
              dash.fetchDashboard();
            } else {
              dash.fetchDashboard();
            }

            // 1. إظهار إشعار نظام حقيقي (شريط الإشعارات للأندرويد وتوست الويندوز)
            NotificationService.instance.showSystemNotification(
              id: latest.id,
              title: latest.title,
              body: latest.message,
              payload: latest.link,
            );

            // 2. إظهار التوست التفاعلي العائم داخل التطبيق
            if (mounted) {
              InAppNotificationToast.show(
                context,
                latest,
                onTap: () => _handleNotificationTap(latest),
              );
            }
          },
        );
      },
      child: Scaffold(
        key: _scaffoldKey,
        // للهاتف: استخدام Drawer جانبي يفتح من اليمين (RTL) ولا يوجد أي BottomNavigationBar
        drawer: isDesktop ? null : _buildDrawer(unreadCount),
        appBar: AppBar(
          leading: isDesktop
              ? null
              : IconButton(
                  icon: const Icon(Icons.menu_rounded, size: 26),
                  tooltip: 'القائمة الرئيسية',
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
          title: Row(
            children: [
              Text(
                _titles[_index],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13805D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF13805D).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Color(0xFF13805D)),
                      SizedBox(width: 4),
                      Text(
                        'بوابة المهندس الميداني',
                        style: TextStyle(
                          color: Color(0xFF13805D),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            // زر التحديث اليدوي
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث البيانات',
              onPressed: _refreshAll,
            ),
            // شارة التنبيهات
            if (_index != 3)
              NotificationBadgeButton(
                onTap: () => setState(() => _index = 3),
              ),
            // زر إضافة تقرير في سطح المكتب
            if (isDesktop && _index != 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportFormScreen(api: widget.api),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('تقرير جديد'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ),
            if (!isDesktop) ...[
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'تسجيل الخروج',
                onPressed: _logout,
              ),
            ],
            const SizedBox(width: 8),
          ],
        ),
        body: isDesktop
            // للويندوز والتابلت: قائمة جانبية مفتوحة دائماً على اليمين في الـ RTL
            ? Row(
                children: [
                  _buildPermanentSidebar(unreadCount),
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                  Expanded(
                    child: IndexedStack(
                      index: _index,
                      children: tabs,
                    ),
                  ),
                ],
              )
            // للهاتف: المحتوى كامل بدون Bottom Bar
            : IndexedStack(
                index: _index,
                children: tabs,
              ),
        floatingActionButton: (_index == 1 || _index == 2)
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xFF13805D),
                foregroundColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportFormScreen(api: widget.api),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('تقرير يومي جديد'),
              )
            : null,
      ),
    );
  }

  /// القائمة الجانبية المفتوحة دائماً للويندوز والتابلت
  Widget _buildPermanentSidebar(int unreadCount) {
    final user = context.watch<AuthProvider>().currentUser;

    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          // رأس القائمة الجانبية مع شعار الشركة
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF13805D).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.engineering_rounded, color: Color(0xFF13805D), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Maxlond Eng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102B3F),
                        ),
                      ),
                      Text(
                        user?.fullName ?? 'المهندس الميداني',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // عناصر التنقل
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _sidebarItem(0, Icons.dashboard_rounded, 'لوحة المهندس', 0),
                const SizedBox(height: 4),
                _sidebarItem(1, Icons.assignment_rounded, 'مهامي الميدانية', 0),
                const SizedBox(height: 4),
                _sidebarItem(2, Icons.description_rounded, 'تقاريري اليومية', 0),
                const SizedBox(height: 4),
                _sidebarItem(3, Icons.notifications_rounded, 'التنبيهات والإشعارات', unreadCount),
              ],
            ),
          ),

          // معلومات الجلسة وزر الخروج
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                if (user?.specialization != null && user!.specialization!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.specialization!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBD3F42),
                    side: const BorderSide(color: Color(0xFFFFCDD2)),
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String title, int badgeCount) {
    final isSelected = _index == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _index = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF13805D).withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: const Color(0xFF13805D).withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? const Color(0xFF13805D) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF13805D) : const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBD3F42),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeCount > 99 ? '+99' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// القائمة المنزلقة (Drawer) للهواتف الذكية
  Widget _buildDrawer(int unreadCount) {
    final user = context.watch<AuthProvider>().currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF13805D), Color(0xFF102B3F)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (user?.fullName.isNotEmpty == true) ? user!.fullName[0] : 'M',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF13805D)),
              ),
            ),
            accountName: Text(
              user?.fullName ?? 'المهندس الميداني',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(user?.email ?? user?.phone ?? 'Maxlond Engineer Portal'),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerTile(0, Icons.dashboard_rounded, 'لوحة المهندس', 0),
                _drawerTile(1, Icons.assignment_rounded, 'مهامي الميدانية', 0),
                _drawerTile(2, Icons.description_rounded, 'تقاريري اليومية', 0),
                _drawerTile(3, Icons.notifications_rounded, 'التنبيهات والإشعارات', unreadCount),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: Color(0xFF13805D)),
                  title: const Text('تقرير يومي جديد'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReportFormScreen(api: widget.api),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(context).pop();
              _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(int index, IconData icon, String title, int badgeCount) {
    final isSelected = _index == index;
    return ListTile(
      selected: isSelected,
      selectedTileColor: const Color(0xFF13805D).withValues(alpha: 0.1),
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF13805D) : const Color(0xFF64748B),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF13805D) : const Color(0xFF1E293B),
        ),
      ),
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFBD3F42),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: () {
        Navigator.of(context).pop();
        setState(() => _index = index);
      },
    );
  }
}
