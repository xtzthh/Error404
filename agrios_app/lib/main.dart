import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login.dart';
import 'theme/colors.dart';
import 'providers/theme_provider.dart';
import 'providers/module_provider.dart';
import 'providers/field_provider.dart';
import 'providers/storage_provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/market_provider.dart';
import 'providers/disease_alert_provider.dart';
import 'providers/krushiai_provider.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final navigatorKey = GlobalKey<NavigatorState>();
  await NotificationService.initialize(navigatorKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ModuleProvider()),
        ChangeNotifierProvider(create: (_) => FieldProvider()),
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => MarketProvider()),
        ChangeNotifierProvider(create: (_) => DiseaseAlertProvider()),
        ChangeNotifierProvider(create: (_) => KrushiAIProvider()),
      ],
      child: AgriOSApp(navigatorKey: navigatorKey),
    ),
  );
}

class AgriOSApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const AgriOSApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;

    return MaterialApp(
      title: 'AGRI-OS BETA V2',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: AppColors.getBg(isDark),
        primaryColor: AppColors.neonGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.neonGreen,
          brightness: isDark ? Brightness.dark : Brightness.light,
          primary: AppColors.neonGreen,
          surface: isDark ? AppColors.cyberBlack : AppColors.lightCard,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
