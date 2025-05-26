import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nemuru/screens/onboarding_screen.dart';
import 'package:nemuru/screens/check_in_screen.dart';
import 'package:nemuru/screens/ai_response_screen.dart';
import 'package:nemuru/screens/log_screen.dart';
import 'package:nemuru/screens/settings_screen.dart';
import 'package:nemuru/theme/app_theme.dart';
import 'package:nemuru/services/notification_service.dart';
import 'package:nemuru/services/preferences_service.dart';
import 'package:nemuru/services/subscription_service.dart';
import 'package:nemuru/services/purchase_service.dart';
import 'package:nemuru/services/chat_log_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ldellkrfbgzrheisjret.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxkZWxsa3JmYmd6cmhlaXNqcmV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgyMzg3MDgsImV4cCI6MjA2MzgxNDcwOH0.hFMbnqOdHIoROefUre-s7FLMowTh9nbmgV0bs46IrgY',
  );
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize date formatting for Japanese locale
  await initializeDateFormatting('ja_JP', null);
  Intl.defaultLocale = 'ja_JP';
  
  // Initialize services
  final preferencesService = PreferencesService();
  await preferencesService.init();
  
  final notificationService = NotificationService();
  await notificationService.init();
  
  // サブスクリプションサービスを初期化
  final subscriptionService = SubscriptionService(preferencesService);
  
  // 購入サービスを初期化
  final purchaseService = PurchaseService(preferencesService, subscriptionService);
  
  // チャットログサービスを初期化
  final chatLogService = ChatLogService(subscriptionService);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => preferencesService),
        Provider(create: (_) => notificationService),
        ChangeNotifierProvider(create: (_) => subscriptionService),
        ChangeNotifierProvider(create: (_) => purchaseService),
        ChangeNotifierProvider(create: (_) => chatLogService),
      ],
      child: const NemuruApp(),
    ),
  );
}

class NemuruApp extends StatelessWidget {
  const NemuruApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final preferencesService = Provider.of<PreferencesService>(context);
    final bool showOnboarding = !preferencesService.onboardingCompleted;
    
    return MaterialApp(
      title: 'NEMURU',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: preferencesService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialRoute: showOnboarding ? '/onboarding' : '/check-in',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/check-in': (context) => const CheckInScreen(),
        '/log': (context) => const LogScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      // AIResponseScreenは引数を受け取るため、onGenerateRouteで処理
      onGenerateRoute: (settings) {
        if (settings.name == '/ai-response') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => AIResponseScreen(
              chatLog: args?['chatLog'],
              characterId: args?['characterId'],
              mood: args?['mood'],
              initialReflection: args?['initialReflection'],
            ),
          );
        }
        return null;
      },
    );
  }
}
