import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'services/engineer_api.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/notifications_provider.dart';
import 'screens/splash_screen.dart';

class MaxlondEngineerApp extends StatelessWidget {
  const MaxlondEngineerApp({super.key, required this.api});
  final EngineerApi api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api: api)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(api: api)),
        ChangeNotifierProvider(create: (_) => TasksProvider(api: api)),
        ChangeNotifierProvider(create: (_) => ReportsProvider(api: api)),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(api: api)),
      ],
      child: MaterialApp(
        title: 'Maxlond Engineer',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF13805d), // أخضر للمهندس
          ),
        ),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: SplashScreen(api: api),
      ),
    );
  }
}
