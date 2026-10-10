import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

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
  final List<XFile> _reportPhotos = [];
  final ImagePicker _picker = ImagePicker();

  int? _siteId;
  DateTime _date = DateTime.now();
  bool _isSubmittingWithUploads = false;
  String _uploadStatusMessage = '';

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
        'receipt_path': null,
        'receipt_name': null,
      });
    });
  }

  Future<ImageSource?> _showSourceSelector(String title) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF102B3F),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13805D).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF13805D)),
                ),
                title: const Text('التقاط صورة بالكاميرا 📷'),
                subtitle: const Text('فتح كاميرا الجهاز وأخذ لقطة مباشرة'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102B3F).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Color(0xFF102B3F)),
                ),
                title: const Text('اختيار من المعرض / الاستوديو 🖼️'),
                subtitle: const Text('تحديد صورة محفوظة في الجهاز أو الحاسوب'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickReceiptForExpense(int index) async {
    final source = await _showSourceSelector('إرفاق وصل بند المصروف');
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _expenses[index]['receipt_path'] = picked.path;
          _expenses[index]['receipt_name'] = picked.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر التقاط/اختيار الصورة: $e')),
        );
      }
    }
  }

  void _removeReceiptFromExpense(int index) {
    setState(() {
      _expenses[index]['receipt_path'] = null;
      _expenses[index]['receipt_name'] = null;
    });
  }

  Future<void> _pickReportPhotos() async {
    final source = await _showSourceSelector('إضافة صور ومرفقات للتقرير');
    if (source == null) return;

    try {
      if (source == ImageSource.camera) {
        final picked = await _picker.pickImage(source: ImageSource.camera);
        if (picked != null) {
          setState(() => _reportPhotos.add(picked));
        }
      } else {
        final pickedList = await _picker.pickMultiImage();
        if (pickedList.isNotEmpty) {
          setState(() => _reportPhotos.addAll(pickedList));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر اختيار الصور: $e')),
        );
      }
    }
  }

  void _removeReportPhoto(int index) {
    setState(() => _reportPhotos.removeAt(index));
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
      title: 'تأكيد إرسال التقرير اليومي',
      content:
          'هل أنت متأكد من دقة البيانات وإرسال التقرير ورفع المرفقات إلى الإدارة؟',
      confirmLabel: 'إرسال التقرير',
    );

    if (!confirmed) return;

    setState(() {
      _isSubmittingWithUploads = true;
      _uploadStatusMessage = 'جاري إرسال بيانات التقرير اليومي...';
    });

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

    final reportPayload = {
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
    };

    final reportId = await reportsProv.createReport(reportPayload);

    if (reportId == null || reportId == 0) {
      if (mounted) {
        setState(() => _isSubmittingWithUploads = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '❌ ${reportsProv.errorMessage ?? "تعذر إرسال التقرير اليومي"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // رفع صور وصولات المصروفات
    int totalUploads = 0;
    final expenseReceipts = _expenses
        .where((e) => e['receipt_path'] != null)
        .toList();

    totalUploads += expenseReceipts.length;
    totalUploads += _reportPhotos.length;

    if (totalUploads > 0 && mounted) {
      setState(() {
        _uploadStatusMessage = 'جاري رفع المرفقات والوصولات ($totalUploads)...';
      });

      // 1. رفع وصولات المصروفات
      for (int i = 0; i < expenseReceipts.length; i++) {
        final exp = expenseReceipts[i];
        final path = exp['receipt_path'] as String;
        final name = (exp['receipt_name'] as String?) ?? 'وصل_مصروف_${i + 1}.jpg';

        setState(() {
          _uploadStatusMessage =
              'جاري رفع وصل المصروف (${i + 1}/${expenseReceipts.length})...';
        });

        await reportsProv.uploadReceipt(
          reportId: reportId,
          filePath: path,
          fileName: name,
        );
      }

      // 2. رفع صور التقرير المتعددة
      for (int i = 0; i < _reportPhotos.length; i++) {
        final photo = _reportPhotos[i];
        setState(() {
          _uploadStatusMessage =
              'جاري رفع صورة التقرير (${i + 1}/${_reportPhotos.length})...';
        });

        await reportsProv.uploadReceipt(
          reportId: reportId,
          filePath: photo.path,
          fileName: photo.name,
        );
      }
    }

    if (!mounted) return;
    setState(() => _isSubmittingWithUploads = false);

    dashboardProv.fetchDashboard();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم إرسال التقرير اليومي ورفع كافة المرفقات بنجاح'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop(true);
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
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 28 : 16,
                vertical: 20,
              ),
              children: [
                // الشاشات العريضة (ويندوز وتابلت): عمودان متجاوران يأخذان كامل عرض الشاشة
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            _buildSiteAndWeatherCard(sites, isWide),
                            const SizedBox(height: 16),
                            _buildMetricsCard(isWide),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        flex: 1,
                        child: _buildWorkDetailsCard(isWide),
                      ),
                    ],
                  )
                else ...[
                  // الهاتف: ترتيب رأسي متناسق
                  _buildSiteAndWeatherCard(sites, isWide),
                  const SizedBox(height: 16),
                  _buildMetricsCard(isWide),
                  const SizedBox(height: 16),
                  _buildWorkDetailsCard(isWide),
                ],

                const SizedBox(height: 20),

                // كارد المصروفات الميدانية مع إرفاق الوصل لكل بند
                _buildExpensesCard(isWide),

                const SizedBox(height: 20),

                // كارد مرفقات وصور التقرير الميداني المتعددة
                _buildPhotosGalleryCard(isWide),

                const SizedBox(height: 28),

                // زر الإرسال النهائي
                _buildSubmitButton(reportsProv, isWide),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // مؤشر التحميل الكامل أثناء الرفع والإرسال
          if (_isSubmittingWithUploads)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              alignment: Alignment.center,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF13805D)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _uploadStatusMessage,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================== كروت النموذج ==================

  Widget _buildSiteAndWeatherCard(
      List<Map<String, dynamic>> sites, bool isWide) {
    return Card(
      elevation: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: Color(0xFF13805D), size: 20),
                SizedBox(width: 8),
                Text(
                  'بيانات الموقع والطقس',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102B3F),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(flex: 3, child: _buildSiteDropdown(sites)),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: _buildDatePicker()),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(flex: 3, child: _buildWeatherField()),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: _buildTempField()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard(bool isWide) {
    return Card(
      elevation: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.engineering_rounded,
                    color: Color(0xFF13805D), size: 20),
                SizedBox(width: 8),
                Text(
                  'الموارد البشرية والمعدات ونسبة الإنجاز',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102B3F),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _workersCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد العمال',
                      prefixIcon: Icon(Icons.people_outline_rounded, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _machineryCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الآليات',
                      prefixIcon: Icon(
                          Icons.precision_manufacturing_outlined,
                          size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _progressCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'نسبة الإنجاز %',
                      prefixIcon: Icon(Icons.trending_up_rounded, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkDetailsCard(bool isWide) {
    return Card(
      elevation: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_outlined,
                    color: Color(0xFF13805D), size: 20),
                SizedBox(width: 8),
                Text(
                  'تفاصيل وسير الأعمال المنجزة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102B3F),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            TextFormField(
              controller: _workDoneCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'الأعمال المنجزة اليوم *',
                hintText: 'اكتب بالتفصيل ما تم إنجازه خلال ساعات العمل...',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الأعمال المنجزة مطلوبة' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _issuesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'المشاكل والعوائق إن وجدت',
                hintText: 'انقطاع تيار، تأخر توريد، أعطال...',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _materialsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'المواد المستخدمة في الموقع',
                hintText: 'أسمنت، حديد تسليح، حصى، رمل، أنابيب...',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _safetyCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات السلامة والبيئة المهنية',
                hintText: 'ارتداء الخوذ، إجراءات السلامة المتبعة...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesCard(bool isWide) {
    return Card(
      elevation: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payments_outlined,
                    color: Color(0xFF13805D), size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المصروفات النثرية الميدانية وإرفاق الوصولات',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF102B3F),
                        ),
                      ),
                      Text(
                        'أضف بنود المصروف وأرفق صورة الوصل بالكاميرا أو المعرض لكل بند',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _addExpense,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة بند مصروف'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF102B3F),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_expenses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 36, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'لم يتم إضافة أي بنود مصروفات (اختياري)',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
              )
            else ...[
              ..._expenses.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return ExpenseRow(
                  index: i,
                  itemName: e['item_name'] as String,
                  category: e['category'] as String,
                  quantity: (e['quantity'] as num).toDouble(),
                  unitPrice: (e['unit_price'] as num).toDouble(),
                  receiptPath: e['receipt_path'] as String?,
                  receiptName: e['receipt_name'] as String?,
                  onItemNameChanged: (val) => e['item_name'] = val,
                  onCategoryChanged: (val) => e['category'] = val,
                  onQuantityChanged: (val) => e['quantity'] = val,
                  onUnitPriceChanged: (val) => e['unit_price'] = val,
                  onAttachReceipt: () => _pickReceiptForExpense(i),
                  onRemoveReceipt: () => _removeReceiptFromExpense(i),
                  onDelete: () => setState(() => _expenses.removeAt(i)),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosGalleryCard(bool isWide) {
    return Card(
      elevation: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF13805D), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مرفقات وصور التقرير الميداني (${_reportPhotos.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF102B3F),
                        ),
                      ),
                      const Text(
                        'التقط أو اختر صوراً متعددة لموقع العمل والأعمال المنجزة للتوثيق',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickReportPhotos,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  label: const Text('إضافة صور 📷'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_reportPhotos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        size: 36, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'لا توجد صور مرفقة بعد — انقر فوق "إضافة صور" للالتقاط أو الاختيار',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _reportPhotos.asMap().entries.map((entry) {
                  final i = entry.key;
                  final photo = entry.value;

                  return Container(
                    width: isWide ? 160 : 130,
                    height: isWide ? 160 : 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (kIsWeb)
                          const Center(child: Icon(Icons.image, size: 40))
                        else
                          Image.file(
                            File(photo.path),
                            fit: BoxFit.cover,
                          ),
                        // تظليل علوي لزر الحذف
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _removeReportPhoto(i),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        // شارة اسم الملف أسفل الصورة
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            child: Text(
                              photo.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ReportsProvider reportsProv, bool isWide) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FilledButton.icon(
        onPressed: (_isSubmittingWithUploads || reportsProv.isSaving)
            ? null
            : _save,
        icon: (_isSubmittingWithUploads || reportsProv.isSaving)
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded, size: 22),
        label: Text(
          (_isSubmittingWithUploads || reportsProv.isSaving)
              ? 'جاري إرسال التقرير ورفع المرفقات...'
              : 'إرسال التقرير اليومي للإدارة',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: const Color(0xFF13805D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        child: Text(_fmt(_date),
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildWeatherField() {
    return TextFormField(
      controller: _weatherCtrl,
      decoration: const InputDecoration(
        labelText: 'حالة الطقس (مثال: مشمس، غائم، ممطر)',
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildTempField() {
    return TextFormField(
      controller: _tempCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'درجة الحرارة (مئوية)',
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
