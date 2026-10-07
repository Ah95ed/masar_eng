import 'package:flutter/material.dart';
import 'core/secure_storage.dart';
import 'services/session_manager.dart';
import 'services/engineer_api.dart';
import 'app.dart';

const _origin = 'https://vehiclegate.ghusun.net';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorage.instance.init();
  await SessionManager.instance.restore();
  final api = EngineerApi(origin: _origin);
  runApp(MaxlondEngineerApp(api: api));
}
