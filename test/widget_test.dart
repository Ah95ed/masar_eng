import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:masar_eng/core/secure_storage.dart';
import 'package:masar_eng/services/session_manager.dart';
import 'package:masar_eng/services/engineer_api.dart';
import 'package:masar_eng/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App basic smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await SecureStorage.instance.init();
    await SessionManager.instance.restore();

    final api = EngineerApi(origin: 'https://vehiclegate.ghusun.net');
    await tester.pumpWidget(MaxlondEngineerApp(api: api));
    expect(find.byType(MaxlondEngineerApp), findsOneWidget);
  });
}
