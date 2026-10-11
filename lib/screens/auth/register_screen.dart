import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../services/engineer_api.dart';
import '../../providers/auth_provider.dart';
import '../../core/responsive.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.api});
  final EngineerApi api;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String _specialization = 'مهندس مدني';
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final List<String> _specializations = const [
    'مهندس مدني',
    'مهندس معماري',
    'مهندس كهرباء',
    'مهندس ميكانيك',
    'مهندس مساحة',
    'إدارة مشاريع إنشائية',
    'مهندس سلامة وبيئة مهنية',
    'أخرى',
  ];

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      fullName: _fullNameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim(),
      specialization: _specialization,
    );

    if (!mounted) return;

    if (success) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          icon: Icon(
            Icons.check_circle_rounded,
            color: const Color(0xFF13805D),
            size: 48.r,
          ),
          title: const Text(
            'تم تسجيل الحساب بنجاح',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'تم تسجيل بيانات المهندس بنجاح في النظام. يمكنك الآن تسجيل الدخول بحسابك.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // العودة لشاشة تسجيل الدخول
              },
              child: const Text('تسجيل الدخول الآن'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final auth = context.watch<AuthProvider>();
    final isWide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: isWide ? const Color(0xFFF1F5F9) : null,
      appBar: AppBar(
        title: const Text('تسجيل مهندس جديد'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 24.w : 16.w,
              vertical: 24.h,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: isWide ? 4 : 0,
                color: isWide ? Colors.white : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  side: isWide
                      ? BorderSide(color: Colors.grey.withAlpha(40))
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: EdgeInsets.all(isWide ? 32.r : 0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 64.r,
                          color: primaryColor,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'إنشاء حساب مهندس جديد',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF102B3F),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'أدخل بياناتك للانضمام إلى بوابة مهندسي الموقع الميداني',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // رسالة خطأ إن وجدت
                        if (auth.errorMessage != null)
                          Container(
                            padding: EdgeInsets.all(12.r),
                            margin: EdgeInsets.only(bottom: 20.h),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                  size: 20.r,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // الاسم الكامل
                        TextFormField(
                          controller: _fullNameCtrl,
                          decoration: InputDecoration(
                            labelText: 'الاسم الكامل *',
                            hintText: 'مثال: م. أحمد محمد',
                            prefixIcon: Icon(Icons.badge_outlined, size: 20.r),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 14.h),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'يرجى إدخال الاسم الكامل';
                            }
                            if (v.trim().length < 3) {
                              return 'يجب أن لا يقل الاسم عن 3 أحرف';
                            }
                            return null;
                          },
                          enabled: !auth.isLoading,
                        ),
                        SizedBox(height: 14.h),

                        // اسم المستخدم
                        TextFormField(
                          controller: _usernameCtrl,
                          decoration: InputDecoration(
                            labelText: 'اسم المستخدم (لتسجيل الدخول) *',
                            hintText: 'مثال: ahmed_eng',
                            prefixIcon: Icon(Icons.alternate_email_rounded,
                                size: 20.r),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 14.h),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'اسم المستخدم مطلوب';
                            }
                            if (v.trim().contains(' ')) {
                              return 'اسم المستخدم لا يجب أن يحتوي على مسافات';
                            }
                            return null;
                          },
                          enabled: !auth.isLoading,
                        ),
                        SizedBox(height: 14.h),

                        // البريد الإلكتروني
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'البريد الإلكتروني *',
                            hintText: 'name@example.com',
                            prefixIcon: Icon(Icons.email_outlined, size: 20.r),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 14.h),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'البريد الإلكتروني مطلوب';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'يرجى إدخال بريد إلكتروني صالح';
                            }
                            return null;
                          },
                          enabled: !auth.isLoading,
                        ),
                        SizedBox(height: 14.h),

                        // رقم الهاتف
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'رقم الهاتف الميداني (اختياري)',
                            hintText: '07xxxxxxxxx',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20.r),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 14.h),
                          ),
                          enabled: !auth.isLoading,
                        ),
                        SizedBox(height: 14.h),

                        // التخصص الهندسي
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _specialization,
                          decoration: InputDecoration(
                            labelText: 'التخصص الهندسي *',
                            prefixIcon:
                                Icon(Icons.engineering_outlined, size: 20.r),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 14.h),
                          ),
                          items: _specializations.map((spec) {
                            return DropdownMenuItem<String>(
                              value: spec,
                              child: Text(
                                spec,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13.5.sp),
                              ),
                            );
                          }).toList(),
                          onChanged: auth.isLoading
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setState(() => _specialization = val);
                                  }
                                },
                        ),
                        SizedBox(height: 14.h),

                        // كلمة المرور
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePass,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور *',
                            prefixIcon: Icon(Icons.lock_outline, size: 20.r),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20.r,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePass = !_obscurePass),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 14.h),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'كلمة المرور مطلوبة';
                            }
                            if (v.length < 6) {
                              return 'يجب أن لا تقل كلمة المرور عن 6 أحرف';
                            }
                            return null;
                          },
                          enabled: !auth.isLoading,
                        ),
                        SizedBox(height: 14.h),

                        // تأكيد كلمة المرور
                        TextFormField(
                          controller: _confirmPassCtrl,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'تأكيد كلمة المرور *',
                            prefixIcon:
                                Icon(Icons.lock_reset_rounded, size: 20.r),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20.r,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 14.h),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'يرجى تأكيد كلمة المرور';
                            }
                            if (v != _passwordCtrl.text) {
                              return 'كلمات المرور غير متطابقة';
                            }
                            return null;
                          },
                          enabled: !auth.isLoading,
                        ),
                        SizedBox(height: 24.h),

                        // زر إنشاء الحساب
                        FilledButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: auth.isLoading
                              ? SizedBox(
                                  height: 20.r,
                                  width: 20.r,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'إنشاء الحساب والتسجيل',
                                  style: TextStyle(fontSize: 16.sp),
                                ),
                        ),
                        SizedBox(height: 16.h),

                        // رابط تسجيل الدخول
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'لديك حساب بالفعل؟',
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
