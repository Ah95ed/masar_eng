import 'package:flutter/material.dart';
import 'package:masar_eng/core/secure_storage.dart';
import 'package:masar_eng/services/session_manager.dart';
import 'package:masar_eng/services/engineer_api.dart';
import 'package:masar_eng/core/api_exception.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorage.instance.init();
  await SessionManager.instance.restore();

  final api = EngineerApi(origin: 'https://vehiclegate.ghusun.net');

  debugPrint('=== Test 1: Login ===');
  try {
    final user = await api.login(
      username: 'montather', // ← اسم مستخدم المهندس
      password: 'كلمة المرور', // ← كلمة مرور المهندس
    );
    debugPrint('✅ Login OK: ${user['full_name']} (${user['role']})');
  } catch (e) {
    debugPrint('❌ Login failed: $e');
    return;
  }

  debugPrint('=== Test 2: Dashboard ===');
  try {
    final data = await api.get('dashboard');
    debugPrint('✅ Dashboard: $data');
  } on ApiException catch (e) {
    debugPrint('❌ Dashboard: ${e.code} - ${e.message}');
  }

  debugPrint('=== Test 3: Sites ===');
  try {
    final data = await api.get('sites');
    debugPrint('✅ Sites: ${(data as List).length}');
  } on ApiException catch (e) {
    debugPrint('❌ Sites: ${e.code} - ${e.message}');
  }

  debugPrint('=== Test 4: Tasks ===');
  try {
    final data = await api.get('tasks');
    debugPrint('✅ Tasks: ${(data as List).length}');
  } on ApiException catch (e) {
    debugPrint('❌ Tasks: ${e.code} - ${e.message}');
  }

  debugPrint('=== Test 5: Reports ===');
  try {
    final data = await api.get('reports');
    debugPrint('✅ Reports: ${(data as List).length}');
  } on ApiException catch (e) {
    debugPrint('❌ Reports: ${e.code} - ${e.message}');
  }

  debugPrint('=== Test 6: Notifications ===');
  try {
    final data = await api.get('notifications');
    debugPrint('✅ Notifications: ${(data as List).length}');
  } on ApiException catch (e) {
    debugPrint('❌ Notifications: ${e.code} - ${e.message}');
  }
}
