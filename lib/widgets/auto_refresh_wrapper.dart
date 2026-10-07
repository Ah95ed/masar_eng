import 'dart:async';
import 'package:flutter/material.dart';

class AutoRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Duration interval;

  const AutoRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.interval = const Duration(seconds: 12),
  });

  @override
  State<AutoRefreshWrapper> createState() => _AutoRefreshWrapperState();
}

class _AutoRefreshWrapperState extends State<AutoRefreshWrapper> with WidgetsBindingObserver {
  Timer? _timer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) => _execute());
  }

  Future<void> _execute() async {
    if (_isRefreshing || !mounted) return;
    _isRefreshing = true;
    try {
      await widget.onRefresh();
    } catch (_) {
    } finally {
      if (mounted) {
        _isRefreshing = false;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _execute();
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
