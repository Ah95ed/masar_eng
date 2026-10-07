import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/tasks_provider.dart';
import '../../core/responsive.dart';
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
      case 'urgent': return const Color(0xFFBD3F42);
      case 'high': return const Color(0xFFB76B08);
      case 'medium': return const Color(0xFF078DA5);
      default: return Colors.grey.shade600;
    }
  }

  String _priorityLabel(String p) {
    switch (p) {
      case 'urgent': return 'عاجل جداً';
      case 'high': return 'أولوية عالية';
      case 'medium': return 'متوسطة';
      case 'low': return 'منخفضة';
      default: return p;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending': return 'بالانتظار';
      case 'in_progress': return 'قيد التنفيذ';
      case 'review': return 'قيد المراجعة';
      case 'done': return 'مكتملة';
      case 'cancelled': return 'ملغاة';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'done': return const Color(0xFF13805D);
      case 'in_progress': return const Color(0xFF078DA5);
      case 'review': return const Color(0xFF8E24AA);
      case 'cancelled': return Colors.grey;
      default: return const Color(0xFFB76B08);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksProv = context.watch<TasksProvider>();
    final filtered = tasksProv.filteredTasks;
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);
    final gridCols = Responsive.gridColumns(context, mobile: 1, tablet: 2, desktop: 3);

    return Column(
      children: [
        // شريط التصفية والبحث
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: 12,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip(context, '', 'الكل (${tasksProv.tasks.length})', tasksProv.filterStatus),
                      const SizedBox(width: 8),
                      _chip(context, 'in_progress', 'قيد التنفيذ', tasksProv.filterStatus),
                      const SizedBox(width: 8),
                      _chip(context, 'pending', 'بالانتظار', tasksProv.filterStatus),
                      const SizedBox(width: 8),
                      _chip(context, 'review', 'مراجعة', tasksProv.filterStatus),
                      const SizedBox(width: 8),
                      _chip(context, 'done', 'مكتملة', tasksProv.filterStatus),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // المحتوى: ListView للهاتف و GridView للويندوز والتابلت
        Expanded(
          child: tasksProv.isLoading
              ? const LoadingState(message: 'جاري تحميل المهام الميدانية...')
              : tasksProv.errorMessage != null
                  ? ErrorState(
                      message: tasksProv.errorMessage!,
                      onRetry: () => context.read<TasksProvider>().fetchTasks(),
                    )
                  : filtered.isEmpty
                      ? const EmptyState(
                          message: 'لا توجد مهام مطابقة للفلتر المحدد',
                          icon: Icons.checklist_rtl_rounded,
                        )
                      : RefreshIndicator(
                          onRefresh: () => context.read<TasksProvider>().fetchTasks(),
                          child: isMobile
                              // =================== عرض الهاتف (ListView) ===================
                              ? ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (context, i) => _buildMobileCard(filtered[i]),
                                )
                              // =================== عرض الويندوز والتابلت (GridView) ===================
                              : GridView.builder(
                                  padding: const EdgeInsets.all(24),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: gridCols,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: isDesktop ? 1.55 : 1.4,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, i) => _buildDesktopCard(filtered[i]),
                                ),
                        ),
        ),
      ],
    );
  }

  /// كارد مخصص للهاتف (Compact Mobile Card)
  Widget _buildMobileCard(Map<String, dynamic> t) {
    final progress = ((t['progress'] ?? 0) as num).toInt();
    final priority = '${t['priority']}';
    final status = '${t['status']}';

    return Card(
      elevation: 0.8,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(api: widget.api, task: t),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${t['title']}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildTag(_priorityLabel(priority), _priorityColor(priority)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${t['site_name']}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ),
                  _buildStatusPill(status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (progress / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        color: _statusColor(status),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$progress%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// كارد متطور للويندوز والتابلت (Rich Desktop Grid Card)
  Widget _buildDesktopCard(Map<String, dynamic> t) {
    final progress = ((t['progress'] ?? 0) as num).toInt();
    final priority = '${t['priority']}';
    final status = '${t['status']}';

    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(api: widget.api, task: t),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الرأس: العنوان والشارات
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${t['title']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF102B3F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTag(_priorityLabel(priority), _priorityColor(priority)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.business_rounded, size: 15, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${t['site_name']}',
                          style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // الوصف إن وُجد
              if (t['description'] != null && (t['description'] as String).isNotEmpty)
                Text(
                  '${t['description']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),

              // شريط التقدم والإجراء
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusPill(status),
                      Text(
                        'الإنجاز: $progress%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF102B3F)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (progress / 100).clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: _statusColor(status),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _chip(BuildContext context, String value, String label, String currentFilter) {
    final selected = currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF13805D).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF13805D) : const Color(0xFF64748B),
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      onSelected: (_) => context.read<TasksProvider>().setFilterStatus(value),
    );
  }
}
