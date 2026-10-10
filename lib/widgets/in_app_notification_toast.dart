import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notification_model.dart';
import '../core/responsive.dart';

class InAppNotificationToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    NotificationModel notification, {
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 5),
  }) {
    // إزالة أي إشعار سابق معروض حالياً
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    // اهتزاز خفيف للمس على الهواتف
    HapticFeedback.lightImpact();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _InAppToastWidget(
        notification: notification,
        onTap: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
          onTap?.call();
        },
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
        duration: duration,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _InAppToastWidget extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final Duration duration;

  const _InAppToastWidget({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_InAppToastWidget> createState() => _InAppToastWidgetState();
}

class _InAppToastWidgetState extends State<_InAppToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    // إغلاق تلقائي بعد انقضاء المدة
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    if (!_controller.isAnimating) {
      await _controller.reverse();
      if (mounted) widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getTypeColor(String type) {
    if (type.contains('approved')) return const Color(0xFF13805D); // أخضر اعتماد
    if (type.contains('rejected')) return const Color(0xFFBD3F42); // أحمر رفض
    if (type.contains('task')) return const Color(0xFF078DA5); // سماوي مهام
    if (type.contains('broadcast')) return const Color(0xFFE67E22); // برتقالي تعميم
    return const Color(0xFF102B3F); // كحلي افتراضي
  }

  IconData _getTypeIcon(String type) {
    if (type.contains('approved')) return Icons.check_circle_rounded;
    if (type.contains('rejected')) return Icons.error_rounded;
    if (type.contains('task')) return Icons.assignment_rounded;
    if (type.contains('broadcast')) return Icons.campaign_rounded;
    return Icons.notifications_active_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);
    final typeColor = _getTypeColor(widget.notification.type);
    final iconData = _getTypeIcon(widget.notification.type);

    return SafeArea(
      child: Align(
        alignment: isWide ? Alignment.topRight : Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(
            top: 16,
            right: isWide ? 24 : 16,
            left: isWide ? 24 : 16,
          ),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 420 : double.infinity,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: typeColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: typeColor.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: widget.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // أيقونة ملونة حسب نوع الإشعار
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                iconData,
                                color: typeColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // النصوص: العنوان والرسالة
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.notification.title,
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF102B3F),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: typeColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'جديد',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: typeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.notification.message,
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      height: 1.35,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        'انقر للمعاينة ↗',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: typeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // زر الإغلاق السريع
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.grey,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              splashRadius: 16,
                              onPressed: _dismiss,
                              tooltip: 'إغلاق',
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
        ),
      ),
    );
  }
}
