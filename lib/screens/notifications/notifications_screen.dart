import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.api});
  final EngineerApi api;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationsProvider>();
    final items = notifProv.notifications;

    if (notifProv.isLoading && items.isEmpty) {
      return const LoadingState(message: 'جاري تحميل الإشعارات...');
    }

    if (notifProv.errorMessage != null && items.isEmpty) {
      return ErrorState(
        message: notifProv.errorMessage!,
        onRetry: () => context.read<NotificationsProvider>().fetchNotifications(),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (notifProv.unreadCount > 0)
                Badge(
                  label: Text('${notifProv.unreadCount}'),
                  child: const Text('غير مقروءة', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else
                const SizedBox.shrink(),
              TextButton.icon(
                onPressed: items.isEmpty ? null : () => notifProv.markAllAsRead(),
                icon: const Icon(Icons.done_all),
                label: const Text('تعليم الكل كمقروء'),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => notifProv.fetchNotifications(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        message: 'لا توجد إشعارات حالياً',
                        icon: Icons.notifications_off_outlined,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => notifProv.fetchNotifications(),
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      final isRead = n['is_read'] == 1;
                      final id = n['id'] as int;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isRead
                              ? Colors.grey.shade300
                              : const Color(0xFF13805d).withValues(alpha: 0.15),
                          child: Icon(
                            isRead ? Icons.done_all : Icons.notifications,
                            color: isRead ? Colors.grey : const Color(0xFF13805d),
                          ),
                        ),
                        title: Text(
                          '${n['title'] ?? ''}',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text('${n['message'] ?? ''}'),
                        trailing: isRead
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.check, color: Color(0xFF13805d)),
                                tooltip: 'تعليم كمقروء',
                                onPressed: () => notifProv.markAsRead(id),
                              ),
                        onTap: isRead ? null : () => notifProv.markAsRead(id),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
