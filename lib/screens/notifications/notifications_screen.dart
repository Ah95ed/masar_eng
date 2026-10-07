import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../models/notification_model.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/reports_provider.dart';
import '../../widgets/auto_refresh_wrapper.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/empty_state.dart';
import '../tasks/task_detail_screen.dart';
import '../reports/report_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.api});
  final EngineerApi api;

  void _onNotificationTapped(BuildContext context, NotificationModel item) async {
    final prov = context.read<NotificationsProvider>();
    if (!item.isRead) {
      prov.markAsRead(item.id);
    }

    final link = item.link;
    if (link == null || link.isEmpty) return;

    // استخراج المعرف من الرابط
    final uri = Uri.tryParse('https://vehiclegate.ghusun.net/$link');
    final query = uri?.queryParameters ?? {};
    final id = int.tryParse(query['id'] ?? '');

    // التوجيه الذكي للشاشة المعنية
    if (link.contains('tasks') || link.contains('work_plans')) {
      final tasksProv = context.read<TasksProvider>();
      if (id != null) {
        // البحث عن المهمة في القائمة الحالية
        final taskMatch = tasksProv.tasks.firstWhere(
          (t) => t['id'] == id,
          orElse: () => {
            'id': id,
            'title': item.title,
            'site_name': '',
            'description': item.message,
            'priority': 'medium',
            'status': 'in_progress',
            'progress': 0,
          },
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(api: api, task: taskMatch),
          ),
        );
      }
    } else if (link.contains('reports')) {
      if (id != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailScreen(api: api, reportId: id),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationsProvider>();

    return AutoRefreshWrapper(
      interval: const Duration(seconds: 12),
      onRefresh: () async {
        await prov.fetchNotifications(
          silent: true,
          onNewNotificationReceived: (latest) {
            // Cascade refresh: تحديث المهام أو التقارير إذا وصل إشعار مرتبط
            if (latest.type.contains('task')) {
              context.read<TasksProvider>().fetchTasks();
            } else if (latest.type.contains('report')) {
              context.read<ReportsProvider>().fetchReports();
            }
          },
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (prov.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBD3F42).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${prov.unreadCount} تنبيه جديد',
                      style: const TextStyle(
                        color: Color(0xFFBD3F42),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                TextButton.icon(
                  onPressed: prov.items.isEmpty ? null : () => prov.markAllAsRead(),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('تعليم الكل كمقروء'),
                ),
              ],
            ),
          ),
        Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: RefreshIndicator(
                  onRefresh: () => prov.fetchNotifications(),
                  child: prov.isLoading && prov.items.isEmpty
                      ? const LoadingState(message: 'جاري تحميل الإشعارات...')
                      : prov.items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 120),
                                EmptyState(
                                  message: 'لا توجد إشعارات حالياً',
                                  icon: Icons.notifications_off_outlined,
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: prov.items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = prov.items[index];
                                return _NotificationCard(
                                  item: item,
                                  onTap: () => _onNotificationTapped(context, item),
                                );
                              },
                            ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color cardColor = const Color(0xFF078DA5); // أزرق افتراضي
    IconData iconData = Icons.info_outline;

    if (item.type.contains('approved')) {
      cardColor = const Color(0xFF13805D); // أخضر اعتماد
      iconData = Icons.check_circle_rounded;
    } else if (item.type.contains('rejected')) {
      cardColor = const Color(0xFFBD3F42); // أحمر رفض
      iconData = Icons.cancel_rounded;
    } else if (item.type.contains('task')) {
      cardColor = const Color(0xFF078DA5); // سماوي مهام
      iconData = Icons.assignment_rounded;
    } else if (item.type.contains('broadcast')) {
      cardColor = const Color(0xFFB76B08); // برتقالي تعميم
      iconData = Icons.campaign_rounded;
    }

    return Card(
      elevation: item.isRead ? 0.5 : 2,
      color: item.isRead ? Colors.white : cardColor.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: item.isRead ? Colors.grey.shade200 : cardColor.withValues(alpha: 0.4),
          width: item.isRead ? 1 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cardColor.withValues(alpha: 0.12),
                child: Icon(iconData, color: cardColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: const Color(0xFF102B3F),
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')} · ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
