import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cadence/core/constants/app_colors.dart';
import 'package:cadence/core/constants/app_constants.dart';
import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/core/services/alarm_service.dart';
import 'package:cadence/features/dashboard/presentation/screens/dashboard_screen.dart';

/// Global database provider — single instance shared app-wide.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize native alarm manager and notification channels
  try {
    await AlarmService.instance.initialize();
  } catch (_) {
    // Non-fatal fallback for test/desktop runtime environments
  }

  runApp(
    const ProviderScope(
      child: CadenceApp(),
    ),
  );
}

class CadenceApp extends StatelessWidget {
  const CadenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.emerald,
          secondary: AppColors.amber,
          error: AppColors.red,
          onSurface: AppColors.textPrimary,
        ),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
