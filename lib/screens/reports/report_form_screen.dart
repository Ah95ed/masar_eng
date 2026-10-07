import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/engineer_api.dart';
import '../../providers/reports_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/responsive.dart';
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
      confirmLabel: 'إرسال التقرير',
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
    final isWide = Responsive.isWide(context);

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
      appBar: AppBar(
        title: const Text('تقرير العمل اليومي الجديد'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 960 : double.infinity),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.all(isWide ? 24 : 16),
              children: [
                // كارد 1: البيانات العامة للموقع واليوم
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'بيانات الموقع والطقس',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102B3F)),
                        ),
                        const SizedBox(height: 16),

                        // السطر الأول: الموقع والتاريخ
                        if (isWide)
                          Row(
                            children: [
                              Expanded(flex: 3, child: _buildSiteDropdown(sites)),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: _buildDatePicker()),
                            ],
                          )
                        else ...[
                          _buildSiteDropdown(sites),
                          const SizedBox(height: 14),
                          _buildDatePicker(),
                        ],

                        const SizedBox(height: 14),

                        // السطر الثاني: الطقس ودرجة الحرارة
                        if (isWide)
                          Row(
                            children: [
                              Expanded(flex: 3, child: _buildWeatherField()),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: _buildTempField()),
                            ],
                          )
                        else ...[
                          _buildWeatherField(),
                          const SizedBox(height: 14),
                          _buildTempField(),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // كارد 2: الكوادر والإنجاز الميداني
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الموارد البشرية والمعدات ونسبة الإنجاز',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102B3F)),
                        ),
                        const SizedBox(height: 16),

                        if (isWide)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _workersCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'عدد العمالة الميدانية'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _machineryCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'عدد الآليات والمعدات'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _progressCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'نسبة الإنجاز الكلية %'),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _workersCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'عدد العمال'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _machineryCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'عدد الآليات'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _progressCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'نسبة الإنجاز %'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // كارد 3: تفاصيل الأعمال والملاحظات
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تفاصيل وسير الأعمال المنجزة',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF102B3F)),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _workDoneCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'الأعمال المنجزة اليوم *',
                            hintText: 'اكتب بالتفصيل ما تم إنجازه خلال ساعات العمل...',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'الأعمال المنجزة مطلوبة' : null,
                        ),
                        const SizedBox(height: 14),

                        if (isWide)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _issuesCtrl,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'المشاكل والعوائق إن وجدت',
                                    hintText: 'انقطاع تيار، تأخر توريد، أعطال...',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _safetyCtrl,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'ملاحظات السلامة والبيئة المهنية',
                                    hintText: 'ارتداء الخوذ، إجراءات السلامة...',
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          TextFormField(
                            controller: _issuesCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(labelText: 'المشاكل والعوائق إن وجدت'),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _safetyCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(labelText: 'ملاحظات السلامة والبيئة المهنية'),
                          ),
                        ],

                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _materialsCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'المواد المستخدمة في الموقع',
                            hintText: 'أسمنت، حديد تسليح، حصى، أنابيب...',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // كارد 4: المصروفات الميدانية
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'المصروفات النثرية الميدانية',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF102B3F)),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _addExpense,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('إضافة بند مصروف'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF102B3F),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                        if (_expenses.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'لم يتم إضافة أي بنود مصروفات (اختياري)',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              ),
                            ),
                          )
                        else ...[
                          const SizedBox(height: 12),
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
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // زر الإرسال النهائي
                Align(
                  alignment: isWide ? Alignment.centerLeft : Alignment.center,
                  child: FilledButton.icon(
                    onPressed: reportsProv.isSaving ? null : _save,
                    icon: reportsProv.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      reportsProv.isSaving ? 'جاري إرسال التقرير...' : 'إرسال التقرير اليومي للإدارة',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSiteDropdown(List<Map<String, dynamic>> sites) {
    return DropdownButtonFormField<int>(
      initialValue: _siteId,
      decoration: const InputDecoration(
        labelText: 'الموقع الإنشائي *',
      ),
      items: sites.map((s) {
        return DropdownMenuItem<int>(
          value: s['id'] as int,
          child: Text('${s['name']} (${s['code'] ?? ""})'),
        );
      }).toList(),
      onChanged: (v) => setState(() => _siteId = v),
      validator: (v) => v == null ? 'يرجى اختيار الموقع' : null,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاريخ التقرير *',
          suffixIcon: Icon(Icons.calendar_today_rounded),
        ),
        child: Text(_fmt(_date), style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildWeatherField() {
    return TextFormField(
      controller: _weatherCtrl,
      decoration: const InputDecoration(
        labelText: 'حالة الطقس (مثال: مشمس، غائم، ممطر)',
      ),
    );
  }

  Widget _buildTempField() {
    return TextFormField(
      controller: _tempCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'درجة الحرارة (مئوية)',
      ),
    );
  }
}
