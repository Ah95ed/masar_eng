import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/responsive.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.api, required this.task});
  final EngineerApi api;
  final Map<String, dynamic> task;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late double _progress;
  late String _status;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _progress = ((widget.task['progress'] ?? 0) as num).toDouble();
    _status = '${widget.task['status']}';
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tasksProv = context.read<TasksProvider>();
    final dashboardProv = context.read<DashboardProvider>();

    final success = await tasksProv.updateTaskProgress(
      taskId: widget.task['id'] as int,
      progress: _progress.round(),
      status: _status,
      note: _noteCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      dashboardProv.fetchDashboard();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم حفظ تحديث المهمة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${tasksProv.errorMessage ?? "فشل الحفظ"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final isDone = _status == 'done';
    final tasksProv = context.watch<TasksProvider>();
    final isWide = Responsive.isWide(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${t['title']}'),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 28 : 16,
          vertical: 20,
        ),
            children: [
              // كارد معلومات المهمة الأساسية
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${t['title']}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.business_rounded, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'الموقع: ${t['site_name']}',
                                      style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF13805D).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'أولوية: ${t['priority']}',
                              style: const TextStyle(color: Color(0xFF13805D), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      if (t['description'] != null && (t['description'] as String).isNotEmpty) ...[
                        const Divider(height: 24),
                        const Text('تفاصيل ومحددات المهمة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
                        const SizedBox(height: 6),
                        Text('${t['description']}', style: const TextStyle(height: 1.5, color: Color(0xFF1E293B))),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // كارد تحديث الحالة ونسبة الإنجاز (متناسق مع شاشات الويندوز والهاتف)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تحديث نسبة الإنجاز وحالة العمل',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102B3F)),
                      ),
                      const SizedBox(height: 16),

                      // نسبة الإنجاز مع مؤشر بصري
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('نسبة الإنجاز الفعلية', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text('${_progress.round()}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF13805D))),
                                  ],
                                ),
                                Slider(
                                  value: _progress,
                                  min: 0,
                                  max: 100,
                                  divisions: 20,
                                  label: '${_progress.round()}%',
                                  activeColor: const Color(0xFF13805D),
                                  onChanged: isDone ? null : (v) => setState(() => _progress = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // الحالة وملاحظة التحديث
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('الحالة الحالية', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    initialValue: ['pending', 'in_progress', 'review', 'done'].contains(_status) ? _status : 'pending',
                                    decoration: const InputDecoration(border: OutlineInputBorder()),
                                    items: const [
                                      DropdownMenuItem(value: 'pending', child: Text('بالانتظار')),
                                      DropdownMenuItem(value: 'in_progress', child: Text('قيد التنفيذ')),
                                      DropdownMenuItem(value: 'review', child: Text('مراجعة')),
                                      DropdownMenuItem(value: 'done', child: Text('منتهية')),
                                    ],
                                    onChanged: isDone ? null : (v) {
                                      if (v != null) {
                                        setState(() {
                                          _status = v;
                                          if (v == 'done') _progress = 100;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ملاحظة المهندس عن التحديث', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _noteCtrl,
                                    maxLines: 2,
                                    maxLength: 3000,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'اكتب تفاصيل التحديث الميداني...',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        const Text('الحالة الحالية', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: ['pending', 'in_progress', 'review', 'done'].contains(_status) ? _status : 'pending',
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'pending', child: Text('بالانتظار')),
                            DropdownMenuItem(value: 'in_progress', child: Text('قيد التنفيذ')),
                            DropdownMenuItem(value: 'review', child: Text('مراجعة')),
                            DropdownMenuItem(value: 'done', child: Text('منتهية')),
                          ],
                          onChanged: isDone ? null : (v) {
                            if (v != null) {
                              setState(() {
                                _status = v;
                                if (v == 'done') _progress = 100;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('ملاحظة المهندس عن التحديث', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteCtrl,
                          maxLines: 3,
                          maxLength: 3000,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'اكتب تفاصيل التحديث الميداني...',
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      Align(
                        alignment: isWide ? Alignment.centerLeft : Alignment.center,
                        child: FilledButton.icon(
                          onPressed: tasksProv.isUpdating || isDone ? null : _save,
                          icon: tasksProv.isUpdating
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(isDone ? 'المهمة مكتملة' : 'حفظ وإرسال التحديث للإدارة'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
