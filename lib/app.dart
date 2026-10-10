import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'services/engineer_api.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/reports_provider.dart';
import 'providers/notifications_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

class MaxlondEngineerApp extends StatelessWidget {
  const MaxlondEngineerApp({super.key, required this.api});
  final EngineerApi api;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF13805D);
    const darkNavy = Color(0xFF102B3F);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(api: api)),
        ChangeNotifierProvider(create: (_) => DashboardProvider(api: api)),
        ChangeNotifierProvider(create: (_) => TasksProvider(api: api)),
        ChangeNotifierProvider(create: (_) => ReportsProvider(api: api)),
        ChangeNotifierProvider(create: (_) => NotificationsProvider(api: api)),
      ],
      child: MaterialApp(
        navigatorKey: NotificationService.navigatorKey,
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
          scaffoldBackgroundColor: const Color(0xFFF7F9F8),
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryGreen,
            primary: primaryGreen,
            secondary: darkNavy,
            surface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 1,
            iconTheme: IconThemeData(color: darkNavy),
            titleTextStyle: TextStyle(
              color: darkNavy,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0.8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE5E9EB), width: 1),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDDE3EA)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryGreen, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: SplashScreen(api: api),
      ),
    );
  }
}
