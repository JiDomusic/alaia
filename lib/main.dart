import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/app_config.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_AR', null);
  await SupabaseService.instance.initialize();
  runApp(const AlaiaApp());
}

class AlaiaApp extends StatelessWidget {
  const AlaiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alaía - Depilación Definitiva',
      debugShowCheckedModeBanner: false,
      theme: AppConfig.buildTheme(),
      home: const SplashScreen(),
    );
  }
}
