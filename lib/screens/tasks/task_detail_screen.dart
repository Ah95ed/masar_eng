import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/dashboard_provider.dart';

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
      // تحديث إحصائيات لوحة التحكم تلقائياً
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

    return Scaffold(
      appBar: AppBar(title: Text('${t['title']}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الموقع: ${t['site_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('الوصف: ${t['description'] ?? 'لا يوجد'}'),
                  const SizedBox(height: 8),
                  Text('الأولوية: ${t['priority']}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('نسبة الإنجاز', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _progress,
            min: 0,
            max: 100,
            divisions: 20,
            label: '${_progress.round()}%',
            onChanged: isDone ? null : (v) => setState(() => _progress = v),
          ),
          Center(
            child: Text('${_progress.round()}%',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          const Text('الحالة', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const Text('ملاحظة التحديث', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            maxLength: 3000,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'اكتب ملاحظاتك عن التحديث الميداني...',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: tasksProv.isUpdating || isDone ? null : _save,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            child: tasksProv.isUpdating
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isDone ? 'المهمة منتهية' : 'حفظ التحديث'),
          ),
        ],
      ),
    );
  }
}
