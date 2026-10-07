import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/reports_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/expense_row.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, required this.api});
  final EngineerApi api;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workDoneCtrl = TextEditingController();
  final _issuesCtrl = TextEditingController();
  final _materialsCtrl = TextEditingController();
  final _safetyCtrl = TextEditingController();
  final _weatherCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _workersCtrl = TextEditingController(text: '0');
  final _machineryCtrl = TextEditingController(text: '0');
  final _progressCtrl = TextEditingController(text: '0');

  final List<Map<String, dynamic>> _expenses = [];
  int? _siteId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reportsProv = context.read<ReportsProvider>();
      await reportsProv.fetchSites();
      if (mounted && reportsProv.sites.isNotEmpty) {
        setState(() {
          _siteId = reportsProv.sites.first['id'] as int;
        });
      }
    });
  }

  @override
  void dispose() {
    _workDoneCtrl.dispose();
    _issuesCtrl.dispose();
    _materialsCtrl.dispose();
    _safetyCtrl.dispose();
    _weatherCtrl.dispose();
    _tempCtrl.dispose();
    _workersCtrl.dispose();
    _machineryCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addExpense() {
    setState(() {
      _expenses.add({
        'item_name': '',
        'category': 'materials',
        'quantity': 1.0,
        'unit_price': 0.0,
      });
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_siteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الموقع أولاً')),
      );
      return;
    }

    final reportsProv = context.read<ReportsProvider>();
    final dashboardProv = context.read<DashboardProvider>();

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'تأكيد إرسال التقرير',
      content: 'هل أنت متأكد من دقة البيانات وإرسال التقرير إلى الإدارة؟',
      confirmLabel: 'إرسال',
    );

    if (!confirmed) return;

    final cleanedExpenses = _expenses
        .where((e) => (e['item_name'] as String).trim().isNotEmpty)
        .map((e) => {
              'item_name': e['item_name'],
              'category': e['category'],
              'quantity': e['quantity'],
              'unit_price': e['unit_price'],
              'notes': '',
            })
        .toList();

    final success = await reportsProv.createReport({
      'site_id': _siteId,
      'report_date': _fmt(_date),
      'weather': _weatherCtrl.text.trim(),
      'temperature': double.tryParse(_tempCtrl.text.trim()),
      'workers_count': int.tryParse(_workersCtrl.text.trim()) ?? 0,
      'machinery_count': int.tryParse(_machineryCtrl.text.trim()) ?? 0,
      'work_done': _workDoneCtrl.text.trim(),
      'issues': _issuesCtrl.text.trim(),
      'materials_used': _materialsCtrl.text.trim(),
      'safety_notes': _safetyCtrl.text.trim(),
      'progress_percent': int.tryParse(_progressCtrl.text.trim()) ?? 0,
      'expenses': cleanedExpenses,
    });

    if (!mounted) return;

    if (success) {
      // تحديث لوحة التحكم تلقائياً
      dashboardProv.fetchDashboard();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال التقرير اليومي بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${reportsProv.errorMessage ?? "تعذر إرسال التقرير"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProv = context.watch<ReportsProvider>();
    final sites = reportsProv.sites;

    if (reportsProv.isLoadingSites && sites.isEmpty) {
      return const Scaffold(
        body: LoadingState(message: 'جاري تحميل قائمة المواقع...'),
      );
    }

    if (reportsProv.errorMessage != null && sites.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: reportsProv.errorMessage!,
          onRetry: () => reportsProv.fetchSites(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('تقرير يومي جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<int>(
              initialValue: _siteId,
              decoration: const InputDecoration(
                labelText: 'الموقع',
                border: OutlineInputBorder(),
              ),
              items: sites.map((s) {
                return DropdownMenuItem<int>(
                  value: s['id'] as int,
                  child: Text('${s['name']}'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _siteId = v),
              validator: (v) => v == null ? 'يرجى اختيار الموقع' : null,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'تاريخ التقرير',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(_fmt(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _weatherCtrl,
              decoration: const InputDecoration(
                labelText: 'الطقس (مثال: مشمس، غائم)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tempCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'درجة الحرارة م°',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _workersCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد العمال',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _machineryCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الآليات',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _progressCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'نسبة الإنجاز %',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _workDoneCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'الأعمال المنجزة',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الأعمال المنجزة مطلوبة' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _issuesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'المشاكل والعوائق',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _materialsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'المواد المستخدمة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _safetyCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات السلامة',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  child: Text('المصروفات',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                TextButton.icon(
                  onPressed: _addExpense,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة بند'),
                ),
              ],
            ),
            ..._expenses.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return ExpenseRow(
                index: i,
                itemName: e['item_name'] as String,
                category: e['category'] as String,
                quantity: (e['quantity'] as num).toDouble(),
                unitPrice: (e['unit_price'] as num).toDouble(),
                onItemNameChanged: (val) => e['item_name'] = val,
                onCategoryChanged: (val) => e['category'] = val,
                onQuantityChanged: (val) => e['quantity'] = val,
                onUnitPriceChanged: (val) => e['unit_price'] = val,
                onDelete: () => setState(() => _expenses.removeAt(i)),
              );
            }),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: reportsProv.isSaving ? null : _save,
              icon: reportsProv.isSaving
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(reportsProv.isSaving ? 'جاري الإرسال...' : 'إرسال التقرير'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
