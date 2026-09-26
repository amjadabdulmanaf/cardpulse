import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false; // 100% Offline Local Asset Fonts
  final storageService = StorageService();
  await storageService.init();

  runApp(CardPulseApp(storageService: storageService));
}

class CardPulseApp extends StatelessWidget {
  final StorageService storageService;

  const CardPulseApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardPulse',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      home: SplashScreen(storageService: storageService),
    );
  }
}
