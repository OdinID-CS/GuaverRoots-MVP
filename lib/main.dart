import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'services/weather_service.dart';
import 'services/notification_service.dart';
import 'services/feedback_service.dart';
import 'services/tts_service.dart';
import 'services/language_service.dart';
import 'l10n/app_localizations.dart';
import 'models/scan_result.dart';
import 'models/weather_data.dart';
import 'providers/app_providers.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  Hive.registerAdapter(ScanResultAdapter());
  Hive.registerAdapter(WeatherDataAdapter());
  await StorageService.init();
  await WeatherService.init();
  await FeedbackService.init();
  
  // Initialize notifications
  await NotificationService().init();
  
  // Initialize TTS
  await TtsService().init();
  
  // Initialize language service
  LanguageService();
  
  // Initialize cameras
  final cameras = await availableCameras();
  
  runApp(GuaverRootsApp(cameras: cameras));
}

class GuaverRootsApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const GuaverRootsApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme();
    final languageService = LanguageService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        Provider.value(value: cameras),
        Provider.value(value: languageService),
      ],
      child: MaterialApp(
        title: 'GuaverRoots',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Color(AppColors.forestGreen),
            onPrimary: Colors.white,
            secondary: Color(AppColors.limeGreen),
            onSecondary: Colors.black,
            error: Color(AppColors.redPrimary),
            onError: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
            outline: Color(0xFFE0E0E0),
          ),
          useMaterial3: true,
          fontFamily: 'Poppins',
          textTheme: textTheme,
          scaffoldBackgroundColor: const Color(0xFFF5F9F5),
        ),
        locale: languageService.currentLocale,
        supportedLocales: LanguageService.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
