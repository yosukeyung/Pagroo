import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/services/foreground_service_manager.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/onboarding/providers/download_provider.dart';
import 'features/tracking/providers/distance_provider.dart';
import 'features/tracking/providers/timer_provider.dart';
import 'features/history/providers/history_provider.dart';
import 'features/tracking/screens/mode_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await ForegroundServiceManager.init();
  
  // Lock to portrait — driver must not accidentally rotate mid-trip
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
        ChangeNotifierProvider(create: (_) => DistanceProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: const ArgoApp(),
    ),
  );
}

class ArgoApp extends StatelessWidget {
  const ArgoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'Pagroo',
          theme: lightTheme(),
          darkTheme: darkTheme(),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const ModeSelectionScreen(),
        );
      },
    );
  }
}
