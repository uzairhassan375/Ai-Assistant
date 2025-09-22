import 'package:aiassistant1/firebase_options.dart';
import 'package:aiassistant1/screens/home_screen.dart';
import 'package:aiassistant1/services/remote-config-service.dart';
import 'package:api_key_pool/api_key_pool.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:aiassistant1/services/simple_notification_service.dart';
import 'package:aiassistant1/services/settings_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await RemoteConfigService().initialize();
  await ApiKeyPool.init('expense manager');
  
  // Initialize simple notification service
  final notificationService = SimpleNotificationService();
  await notificationService.initialize();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => SettingsService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

      static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
      static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);
  
  // Global navigator key for notifications
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // Add this line
          debugShowCheckedModeBanner: false,
          title: 'HelpMe',
          themeMode: settings.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(settings.fontScale)),
              child: child!,
            );
          },
          // Open app directly to HomeScreen without authentication
          home: const HomeScreen(),
        );
      },
    );
  }
}
