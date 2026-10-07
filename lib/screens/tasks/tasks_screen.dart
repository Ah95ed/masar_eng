import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.api});
  final EngineerApi api;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TasksProvider>().fetchTasks();
    });
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'urgent': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending': return 'بالانتظار';
      case 'in_progress': return 'قيد التنفيذ';
      case 'review': return 'مراجعة';
      case 'done': return 'منتهية';
      case 'cancelled': return 'ملغاة';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksProv = context.watch<TasksProvider>();
    final filtered = tasksProv.filteredTasks;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(context, '', 'الكل', tasksProv.filterStatus),
                const SizedBox(width: 8),
                _chip(context, 'pending', 'بالانتظار', tasksProv.filterStatus),
                const SizedBox(width: 8),
                _chip(context, 'in_progress', 'قيد التنفيذ', tasksProv.filterStatus),
                const SizedBox(width: 8),
                _chip(context, 'review', 'مراجعة', tasksProv.filterStatus),
                const SizedBox(width: 8),
                _chip(context, 'done', 'منتهية', tasksProv.filterStatus),
              ],
            ),
          ),
        ),
        Expanded(
          child: tasksProv.isLoading
              ? const LoadingState(message: 'جاري تحميل المهام...')
              : tasksProv.errorMessage != null
                  ? ErrorState(
                      message: tasksProv.errorMessage!,
                      onRetry: () => context.read<TasksProvider>().fetchTasks(),
                    )
                  : filtered.isEmpty
                      ? const EmptyState(
                          message: 'لا توجد مهام مطابقة',
                          icon: Icons.checklist_rtl_outlined,
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<TasksProvider>().fetchTasks(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final t = filtered[i];
                              final progress = ((t['progress'] ?? 0) as num).toInt();
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TaskDetailScreen(
                                          api: widget.api,
                                          task: t,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${t['title']}',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _priorityColor(
                                                        '${t['priority']}')
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${t['priority']}',
                                                style: TextStyle(
                                                  color: _priorityColor(
                                                      '${t['priority']}'),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${t['site_name']}',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: LinearProgressIndicator(
                                                value: (progress / 100).clamp(0.0, 1.0),
                                                minHeight: 6,
                                                borderRadius: BorderRadius.circular(4),
                                                backgroundColor: Colors.grey[200],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('$progress%'),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _statusLabel('${t['status']}'),
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, String value, String label, String currentFilter) {
    final selected = currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => context.read<TasksProvider>().setFilterStatus(value),
    );
  }
}
